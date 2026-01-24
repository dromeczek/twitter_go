import 'package:flutter/material.dart';
import '../models/post_model.dart';

class CreatePostResult {
  final String text;
  final String displayName;
  final double radiusMeters;
  final PostVisibility visibility;

  CreatePostResult({
    required this.text,
    required this.displayName,
    required this.radiusMeters,
    required this.visibility,
  });
}

class CreatePostSheet extends StatefulWidget {
  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _textCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  double _radius = 200;
  PostVisibility _vis = PostVisibility.public;

  @override
  void dispose() {
    _textCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: inset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Dodaj post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nazwa autora', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Treść', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Promień'),
              Expanded(
                child: Slider(
                  value: _radius,
                  min: 50,
                  max: 2000,
                  divisions: 39,
                  label: _radius.toStringAsFixed(0),
                  onChanged: (v) => setState(() => _radius = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Widoczność'),
              const SizedBox(width: 12),
              DropdownButton<PostVisibility>(
                value: _vis,
                items: const [
                  DropdownMenuItem(value: PostVisibility.public, child: Text('Public')),
                  DropdownMenuItem(value: PostVisibility.friends, child: Text('Friends')),
                ],
                onChanged: (v) => setState(() => _vis = v ?? PostVisibility.public),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final text = _textCtrl.text.trim();
                if (text.isEmpty) return;

                final name = _nameCtrl.text.trim().isEmpty ? 'User' : _nameCtrl.text.trim();

                Navigator.of(context).pop(
                  CreatePostResult(
                    text: text,
                    displayName: name,
                    radiusMeters: _radius,
                    visibility: _vis,
                  ),
                );
              },
              child: const Text('Dodaj'),
            ),
          ),
        ],
      ),
    );
  }
}
