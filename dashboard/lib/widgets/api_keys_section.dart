import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ApiKeysSection extends StatefulWidget {
  const ApiKeysSection({super.key});

  @override
  State<ApiKeysSection> createState() => _ApiKeysSectionState();
}

class _ApiKeysSectionState extends State<ApiKeysSection> {
  @override
  Widget build(BuildContext context) {
    final apiService = context.watch<ApiService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showGenerateKeyDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Generate New API Key'),
        ),
        const SizedBox(height: 24),
        
        FutureBuilder<List<Map<String, dynamic>>>(
          future: apiService.getApiKeys(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final keys = snapshot.data ?? [];

            if (keys.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No API keys yet. Generate one to get started.'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final key = keys[index];
                final isActive = key['isActive'] == true || key['isActive'] == 1;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      Icons.vpn_key,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                    title: Text(key['name'] ?? 'Unnamed Key'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          key['keyValue'] ?? 'N/A',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${_formatDate(key['createdAt'])}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy to clipboard',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: key['keyValue']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('API key copied to clipboard')),
                            );
                          },
                        ),
                        if (isActive)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Revoke',
                            onPressed: () => _confirmRevoke(context, key['id']),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _showGenerateKeyDialog(BuildContext context) async {
    final nameController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate API Key'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Key Name',
            hintText: 'e.g., Production, Development',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await context.read<ApiService>().generateApiKey(
          nameController.text.isEmpty ? 'Unnamed Key' : nameController.text,
        );
        
        if (mounted) {
          setState(() {}); // Refresh the list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('API key generated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmRevoke(BuildContext context, String keyId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke API Key'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await context.read<ApiService>().revokeApiKey(keyId);
        
        if (mounted) {
          setState(() {}); // Refresh the list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('API key revoked')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
