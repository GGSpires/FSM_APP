import 'package:fsm_app/export.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class JobCardFormScreen extends StatefulWidget {
  const JobCardFormScreen({
    super.key,
    required this.existingCards,
    this.jobCardToEdit,
  });

  final List<JobCardModel> existingCards;
  final JobCardModel? jobCardToEdit;

  @override
  State<JobCardFormScreen> createState() => _JobCardFormScreenState();
}

class _JobCardFormScreenState extends State<JobCardFormScreen> {
  List<ClientModel> _availableClients = [];
  bool _callComplete = false;
  final _clientCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController(); // NEW: Who is signing?
  final _clientRefCtrl = TextEditingController();
  final SignatureController _clientSignCtrl = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final _contactCtrl = TextEditingController();
  String _existingClientSign = '';
  String _existingTechSign = '';
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  // Controllers for ALL fields in the JobCardModel
  final _jcIdCtrl = TextEditingController();

  final _orderNoCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  bool _returnNeeded = false;
  // ignore: unused_field
  ClientModel? _selectedClient;

  final _siteCtrl = TextEditingController();
  final _techCtrl = TextEditingController();
  // Signature Controllers
  final SignatureController _techSignCtrl = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final _workExecutedCtrl = TextEditingController();
  final _workInstructionCtrl = TextEditingController();
  final _worksNoCtrl = TextEditingController();

  late DateTime _selectedDate;
  late DateTime _selectedTimeIn;

  DateTime? _selectedTimeOut; // Nullable until they tap "Time Out"

  @override
  void dispose() {
    _techSignCtrl.dispose();
    _clientSignCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchClients();

    if (widget.jobCardToEdit != null) {
      // EDIT MODE: Load strictly from the database
      _loadExistingData(widget.jobCardToEdit!);
    } else {
      // CREATE MODE: Explicitly set them to "Now" only here
      final now = DateTime.now();
      _selectedDate = now;
      _selectedTimeIn = now;
      _selectedTimeOut = null;

      _autoFillForm(); // Move the rest of the autofill logic here
    }
  }

  Future<void> _fetchClients() async {
    final data = await ApiClient.getTableData(ApiConstants.tableClients);
    if (mounted) {
      setState(() {
        _availableClients = data
            .map((json) => ClientModel.fromJson(json))
            .toList();
      });
    }
  }

  void _loadExistingData(JobCardModel card) {
    _jcIdCtrl.text = card.jcId;
    _worksNoCtrl.text = card.worksNo;
    _clientRefCtrl.text = card.clientRef;
    _orderNoCtrl.text = card.orderNo;
    _techCtrl.text = card.tech;
    _clientCtrl.text = card.client;
    _siteCtrl.text = card.site;
    _contactCtrl.text = card.contact;
    //--------------------------------------------------
    _selectedDate = card.date;
    _selectedTimeIn = card.timeIn;
    _selectedTimeOut = card.timeOut;
    //--------------------------------------------------
    _workInstructionCtrl.text = card.workInstruction;
    _workExecutedCtrl.text = card.workExecuted;
    _remarksCtrl.text = card.remarks;
    _clientNameCtrl.text = card.clientName;
    _callComplete = card.callComplete.toUpperCase() == 'TRUE';
    _returnNeeded = card.returnNeeded.toUpperCase() == 'TRUE';
    _existingTechSign = card.techSign;
    _existingClientSign = card.clientSign;
  }

  // NEW: Must be async because we are reading SharedPreferences
  Future<void> _autoFillForm() async {
    _techCtrl.text = authProvider.currentUser?.alias ?? 'Tech';

    // 1. Find the highest ID currently alive in the database
    int maxDbId = 0;
    for (var card in widget.existingCards) {
      final int? currentId = int.tryParse(card.jcId);
      if (currentId != null && currentId > maxDbId) maxDbId = currentId;
    }

    // 2. Check the device's permanent memory for the highest ID it has EVER seen
    final prefs = await SharedPreferences.getInstance();
    int maxSavedId = prefs.getInt('highest_known_jc_id') ?? 0;

    // 3. The true max ID is whichever is bigger (prevents rollback if highest is deleted)
    int trueMaxId = maxDbId > maxSavedId ? maxDbId : maxSavedId;
    int newId = trueMaxId + 1;

    // 4. Save this new highest number to permanent memory
    await prefs.setInt('highest_known_jc_id', newId);

    // 5. Generate Works Number Sequence
    final now = DateTime.now();
    final String monthStr = now.month.toString().padLeft(2, '0');
    final String yearStr = now.year.toString().substring(2);
    final String prefix = 'KHA$monthStr$yearStr';

    int maxSeq = 0;
    for (var card in widget.existingCards) {
      if (card.worksNo.startsWith(prefix)) {
        final seqStr = card.worksNo.substring(prefix.length);
        final int? seq = int.tryParse(seqStr);
        if (seq != null && seq > maxSeq) maxSeq = seq;
      }
    }

    // 6. Update the UI safely
    if (mounted) {
      setState(() {
        // Enforce the 4-digit rule on the newly generated ID
        _jcIdCtrl.text = newId.toString().padLeft(4, '0');
        _worksNoCtrl.text = '$prefix${(maxSeq + 1).toString().padLeft(2, '0')}';
      });
    }
  }

  // Auto-fill logic when a client is selected from the dropdown
  void _onClientSelected(ClientModel? client) {
    setState(() {
      _selectedClient = client;
      if (client != null) {
        _clientCtrl.text = client.name;
        _siteCtrl.text = client.sites.isNotEmpty
            ? client.sites
            : client.address;
        _contactCtrl.text = client.contactName;
      }
    });
  }

  Future<String> _convertSignatureToBase64(
    SignatureController controller,
  ) async {
    if (controller.isEmpty) return '';
    final ui.Image? image = await controller.toImage();
    if (image == null) return '';
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (data == null) return '';
    return base64Encode(data.buffer.asUint8List());
  }

  Future<void> _submitJobCard() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in red before saving.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      //PREPARE SIGNATURES
      String techSignB64 = _existingTechSign;
      if (_techSignCtrl.isNotEmpty) {
        techSignB64 = await _convertSignatureToBase64(_techSignCtrl);
      }

      String clientSignB64 = _existingClientSign;
      if (_clientSignCtrl.isNotEmpty) {
        clientSignB64 = await _convertSignatureToBase64(_clientSignCtrl);
      }

      //PREPARE PAYLOAD
      Map<String, dynamic> payload = {
        'JC_ID': _jcIdCtrl.text,
        'Works_No': _worksNoCtrl.text,
        'Client_Ref': _clientRefCtrl.text,
        'Order_No': _orderNoCtrl.text,
        'Tech': _techCtrl.text,
        'Client': _clientCtrl.text,
        'Site': _siteCtrl.text,
        'Contact': _contactCtrl.text,
        // ...
        'Date': DateFormat('dd/MM/yyyy').format(_selectedDate),
        'Time_In': DateFormat('HH:mm').format(_selectedTimeIn),
        'Time_Out': _selectedTimeOut != null
            ? DateFormat('HH:mm').format(_selectedTimeOut!)
            : '',
        // ...
        'Work_Instruction': _workInstructionCtrl.text,
        'Work_Executed': _workExecutedCtrl.text,
        'Remarks': _remarksCtrl.text,
        'Call_Complete': _callComplete.toString().toUpperCase(),
        'Return_Needed': _returnNeeded.toString().toUpperCase(),
        'Client_Name': _clientNameCtrl.text,
        'Client_Sign': clientSignB64,
        'Tech_Sign': techSignB64,
      };

      //SEND TO API
      String? errorStr;
      if (widget.jobCardToEdit != null) {
        errorStr = await ApiClient.updateRecordDetailed(
          ApiConstants.tableJobCards,
          'JC_ID',
          widget.jobCardToEdit!.jcId,
          payload,
        );
      } else {
        bool success = await ApiClient.insertRecord(
          ApiConstants.tableJobCards,
          payload,
        );
        // If insertRecord returns false, manual error message
        errorStr = success
            ? null
            : 'Failed to insert Job Card. Check connection.';
      }

      setState(() => _isLoading = false);

      if (errorStr == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job Card Saved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // This will now properly close the screen!
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorStr'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // 3. THIS IS THE CATCH BLOCK THAT CATCHES CRASHES FROM THE TRY BLOCK
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('App Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.withOpacity(0.1) : null,
        ),
        validator: required
            ? (val) => (val == null || val.isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _buildDisplayField(
    String label,
    DateTime? selectedDate,
    DateTime? initialDate,
    bool readOnly,
    DateFormat dateFormat,
    DateTimeFieldPickerMode mode,
    ValueChanged<DateTime?>? onChanged,
  ) {
    // Automatically choose the correct icon based on what the picker is doing
    final IconData displayIcon = mode == DateTimeFieldPickerMode.date
        ? Icons.calendar_today_rounded
        : Icons.access_time_rounded;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16.0,
      ), // Slightly more breathing room
      child: DateTimeField(
        mode: mode,
        dateFormat: dateFormat,
        decoration: InputDecoration(
          labelText: label,
          hintText: selectedDate == null ? 'Tap to set $label' : null,
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
          prefixIcon: Icon(
            displayIcon,
            color: readOnly ? Colors.grey : Theme.of(context).primaryColor,
          ),
          // Clean, modern rounded borders
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          filled: readOnly,
          // Subtle grey background if locked, crisp white if editable
          fillColor: readOnly
              ? Colors.grey.withOpacity(0.1)
              : Colors.transparent,
        ),
        initialPickerDateTime: initialDate ?? DateTime.now(),
        value: selectedDate,
        onChanged: readOnly ? null : onChanged,
      ),
    );
  }

  Widget _buildSignaturePad(
    String title,
    SignatureController controller,
    String existingBase64, //THIS TEXT:
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => controller.clear(),
              child: const Text('Clear Pad'),
            ),
          ],
        ),
        // If an existing signature exists and the user hasn't started drawing a new one, show a hint
        if (existingBase64.isNotEmpty && controller.isEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.green.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  'Signature already saved. Draw to overwrite.',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(width: 2, color: Colors.grey),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Signature(
            controller: controller,
            height: 150,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.jobCardToEdit != null ? 'Edit Job Card' : 'New Job Card',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionHeader('System Identifiers'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _jcIdCtrl,
                          'JC_ID',
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          _worksNoCtrl,
                          'Works No.',
                          readOnly: false,
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(_techCtrl, 'Technician', readOnly: true),

                  _buildSectionHeader('Admin References'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _clientRefCtrl,
                          'Client Ref (Optional)',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          _orderNoCtrl,
                          'Order No (Optional)',
                        ),
                      ),
                    ],
                  ),

                  _buildSectionHeader('Client & Site Details'),
                  // Only show dropdown if the database has records
                  if (_availableClients.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: DropdownButtonFormField<ClientModel>(
                        decoration: const InputDecoration(
                          labelText: 'Quick Fill from Database',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableClients
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: _onClientSelected,
                        isExpanded: true,
                      ),
                    ),

                  // Text fields that are auto-filled by the dropdown, but always manually editable
                  _buildTextField(_clientCtrl, 'Client Name', required: true),
                  _buildTextField(_siteCtrl, 'Site Location', required: true),
                  _buildTextField(_contactCtrl, 'Site Contact', required: true),

                  _buildSectionHeader('Work Execution'),

                  // 1. Date Field (Editable)
                  _buildDisplayField(
                    'Date',
                    _selectedDate,
                    _selectedDate,
                    false, // Editable
                    DateFormat('dd/MM/yyyy'),
                    DateTimeFieldPickerMode.date,
                    (DateTime? value) {
                      if (value != null) {
                        setState(() => _selectedDate = value);
                      }
                    },
                  ),

                  // 2. Time In Field (Editable)
                  _buildDisplayField(
                    'Time In',
                    _selectedTimeIn,
                    _selectedTimeIn,
                    false, // Editable
                    DateFormat('HH:mm'),
                    DateTimeFieldPickerMode.time,
                    (DateTime? value) {
                      if (value != null) {
                        setState(() => _selectedTimeIn = value);
                      }
                    },
                  ),

                  // 3. Time Out Field (Tappable, Initially Blank)
                  _buildDisplayField(
                    'Time Out',
                    _selectedTimeOut, // Passes null initially
                    DateTime.now(), // Opens the clock to the current time when tapped
                    false, // Editable
                    DateFormat('HH:mm'),
                    DateTimeFieldPickerMode.time,
                    (DateTime? value) {
                      if (value != null) {
                        setState(() => _selectedTimeOut = value);
                      }
                    },
                  ),

                  // WORK_INSTRUCTION, WORK_EXECUTED, REMARKS
                  _buildTextField(
                    _workInstructionCtrl,
                    'Work Instruction',
                    required: true,
                    maxLines: 2,
                  ),
                  _buildTextField(
                    _workExecutedCtrl,
                    'Work Executed',
                    required: true,
                    maxLines: 4,
                  ),
                  _buildTextField(
                    _remarksCtrl,
                    'Remarks (Optional)',
                    maxLines: 2,
                  ),

                  //JOB STATUS & CALL COMPLETE/RETURN NEEDED
                  _buildSectionHeader('Job Status'),
                  SwitchListTile(
                    title: const Text('Call Complete'),
                    // 1. If return is needed, force the value to false (optional logic)
                    value: _returnNeeded ? false : _callComplete,
                    // 2. If _returnNeeded is true, onChanged is null, disabling the switch
                    onChanged: _returnNeeded
                        ? null
                        : (val) => setState(() => _callComplete = val),
                  ),
                  SwitchListTile(
                    title: const Text('Return Required'),
                    value: _returnNeeded,
                    onChanged: (val) {
                      setState(() {
                        _returnNeeded = val;
                        // 3. Automatically uncheck 'Complete'  if 'Return' is toggled on
                        if (val) _callComplete = false;
                      });
                    },
                  ),

                  // SIGNATURES
                  _buildSectionHeader('Signatures'),
                  _buildSignaturePad(
                    'Technician Signature',
                    _techSignCtrl,
                    _existingTechSign,
                  ),
                  const SizedBox(height: 24),

                  // NEW FIELD: Who is signing for the client?
                  _buildTextField(_clientNameCtrl, 'Signatory Name (Client)'),
                  const SizedBox(height: 8),
                  _buildSignaturePad(
                    'Client Signature',
                    _clientSignCtrl,
                    _existingClientSign,
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitJobCard,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'SAVE JOB CARD',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
