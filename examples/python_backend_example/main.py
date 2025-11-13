from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import httpx
import asyncio
import random
from datetime import datetime

app = FastAPI(title="Payment Server with API Sentinel")

# Configuration
API_SENTINEL_KEY = "sk_your_api_key_here"
API_SENTINEL_ENDPOINT = "http://localhost:8080/api/v1/analytics/events"


class PaymentRequest(BaseModel):
    amount: float
    currency: str = "USD"
    customerId: Optional[str] = None


class PaymentResponse(BaseModel):
    success: bool
    gateway: str
    transactionId: str
    amount: float
    failedGateway: Optional[str] = None
    recoveryTimeMs: Optional[int] = None


# Simulate Stripe payment
async def charge_stripe(amount: float, currency: str) -> dict:
    await asyncio.sleep(0.2)  # Simulate network delay
    
    # 30% failure rate for demo
    if random.random() < 0.3:
        raise Exception("Stripe gateway timeout")
    
    return {
        "transactionId": f"stripe_txn_{int(datetime.now().timestamp() * 1000)}",
        "amount": amount,
        "currency": currency,
        "gateway": "stripe"
    }


# Simulate PayPal payment
async def charge_paypal(amount: float, currency: str) -> dict:
    await asyncio.sleep(0.25)  # Simulate network delay
    
    # 10% failure rate
    if random.random() < 0.1:
        raise Exception("PayPal processing error")
    
    return {
        "transactionId": f"paypal_txn_{int(datetime.now().timestamp() * 1000)}",
        "amount": amount,
        "currency": currency,
        "gateway": "paypal"
    }


# Report failover event to API Sentinel
async def report_failover_event(event_data: dict):
    try:
        print(f"📊 Reporting to API Sentinel: {event_data}")
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                API_SENTINEL_ENDPOINT,
                json=event_data,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {API_SENTINEL_KEY}"
                }
            )
            
            if response.status_code == 200:
                print("✅ Event reported successfully")
    except Exception as e:
        print(f"⚠️  Failed to report to API Sentinel: {e}")


@app.post("/api/payment/charge", response_model=PaymentResponse)
async def process_payment(payment: PaymentRequest):
    print(f"💳 Processing payment: ${payment.amount} {payment.currency}")
    start_time = datetime.now()
    
    try:
        # Try primary gateway (Stripe)
        result = await charge_stripe(payment.amount, payment.currency)
        print(f"✅ Stripe charge successful: {result['transactionId']}")
        
        return PaymentResponse(
            success=True,
            gateway="stripe",
            transactionId=result["transactionId"],
            amount=payment.amount
        )
    except Exception as stripe_error:
        print(f"❌ Stripe failed: {stripe_error}")
        
        try:
            # Failover to secondary gateway (PayPal)
            result = await charge_paypal(payment.amount, payment.currency)
            recovery_time = int((datetime.now() - start_time).total_seconds() * 1000)
            
            print(f"✅ PayPal charge successful: {result['transactionId']}")
            print(f"⚡ Recovery time: {recovery_time}ms")
            
            # Report to API Sentinel
            await report_failover_event({
                "timestamp": datetime.now().isoformat(),
                "primaryGateway": "stripe",
                "secondaryGateway": "paypal",
                "errorType": "network_timeout" if "timeout" in str(stripe_error).lower() else "gateway_error",
                "amount": payment.amount,
                "currency": payment.currency,
                "success": True,
                "recoveryTimeMs": recovery_time
            })
            
            return PaymentResponse(
                success=True,
                gateway="paypal",
                failedGateway="stripe",
                transactionId=result["transactionId"],
                amount=payment.amount,
                recoveryTimeMs=recovery_time
            )
        except Exception as paypal_error:
            print(f"❌ PayPal also failed: {paypal_error}")
            
            # Report failed failover
            recovery_time = int((datetime.now() - start_time).total_seconds() * 1000)
            await report_failover_event({
                "timestamp": datetime.now().isoformat(),
                "primaryGateway": "stripe",
                "secondaryGateway": "paypal",
                "errorType": "complete_failure",
                "amount": payment.amount,
                "currency": payment.currency,
                "success": False,
                "recoveryTimeMs": recovery_time
            })
            
            raise HTTPException(
                status_code=500,
                detail="All payment gateways failed"
            )


@app.get("/health")
async def health_check():
    return {"status": "OK"}


if __name__ == "__main__":
    import uvicorn
    print("✅ Payment server starting on http://localhost:8000")
    print("📊 API Sentinel integration enabled")
    uvicorn.run(app, host="localhost", port=8000)
