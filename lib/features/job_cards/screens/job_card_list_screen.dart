import 'package:fsm_app/export.dart';

class JobCardListScreen extends StatefulWidget {
  const JobCardListScreen({super.key});

  @override
  JobCardListScreenState createState() => JobCardListScreenState();
}

class JobCardListScreenState extends State<JobCardListScreen> {
  late Future<List<JobCardModel>> _jobCardsFuture;

  @override
  void initState() {
    super.initState();
    fetchJobCards();
  }

  void fetchJobCards() {
    setState(() {
      _jobCardsFuture = ApiClient.getTableData(ApiConstants.tableJobCards).then(
        (data) => data.map((json) => JobCardModel.fromJson(json)).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<JobCardModel>>(
        future: _jobCardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Job Cards found.'));
          }

          final jobCards = snapshot.data!.reversed.toList();

          return RefreshIndicator(
            onRefresh: () async {
              fetchJobCards();
              await _jobCardsFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: jobCards.length,
              itemBuilder: (context, index) {
                final job = jobCards[index];
                final bool isSigned = job.clientSign.isNotEmpty;
                final bool isComplete = job.callComplete == 'TRUE';
                final bool needsReturn = job.returnNeeded == 'TRUE';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${job.jcId} - ${job.site}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => JobCardFormScreen(
                                        existingCards: jobCards,
                                        jobCardToEdit: job,
                                      ),
                                    ),
                                  );
                                  fetchJobCards();
                                } else if (value == 'delete') {
                                  // 1. Confirm with the user first
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Job Card?'),
                                      content: Text(
                                        'Are you sure you want to delete ${job.jcId}? This cannot be undone.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true && context.mounted) {
                                    // 2. Show loading snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Deleting...'),
                                      ),
                                    );

                                    // 3. Call the API
                                    final success =
                                        await ApiClient.deleteRecord(
                                          ApiConstants.tableJobCards,
                                          'JC_ID',
                                          job.jcId,
                                        );

                                    if (context.mounted) {
                                      if (success) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Job Card Deleted'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        // 4. Refresh the list
                                        fetchJobCards();
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to delete. Check connection.',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Job Card'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete Job Card',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),

                        _buildInfoRow(
                          'Works No:',
                          job.worksNo,
                          'Job ID:',
                          job.jcId,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow('Client:', job.client, 'Tech:', job.tech),
                        const SizedBox(height: 8),

                        const Text(
                          'Instruction:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          job.workInstruction.isEmpty
                              ? 'No instruction provided'
                              : job.workInstruction,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            _buildStatusBadge(
                              label: isComplete ? 'Complete' : 'Incomplete',
                              color: isComplete ? Colors.green : Colors.orange,
                              icon: isComplete
                                  ? Icons.check_circle
                                  : Icons.pending,
                            ),
                            if (needsReturn)
                              _buildStatusBadge(
                                label: 'Return Required',
                                color: Colors.red,
                                icon: Icons.assignment_return,
                              ),
                            _buildStatusBadge(
                              label: isSigned ? 'Signed' : 'Unsigned',
                              color: isSigned ? Colors.blue : Colors.grey,
                              icon: isSigned ? Icons.draw : Icons.edit_off,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () async {
          List<JobCardModel> currentCards = [];
          try {
            currentCards = await _jobCardsFuture;
          } catch (e) {
            currentCards = [];
          }

          if (!context.mounted) return;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  JobCardFormScreen(existingCards: currentCards),
            ),
          );

          fetchJobCards();
        },
      ),
    );
  }

  Widget _buildInfoRow(String label1, String val1, String label2, String val2) {
    return Row(
      children: [
        Expanded(
          child: Text('$label1 $val1', style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: Text('$label2 $val2', style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
