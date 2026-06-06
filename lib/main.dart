import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const FileSearchApp());

class FileSearchApp extends StatelessWidget {
  const FileSearchApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '秒级文件搜索', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true, brightness: Brightness.dark),
    home: const FileSearchHomePage(),
  );
}

class FileResult {
  final String name, path, size, type, modified;
  FileResult({required this.name, required this.path, required this.size, required this.type, required this.modified});
}

class FileSearchHomePage extends StatefulWidget {
  const FileSearchHomePage({super.key});
  @override
  State<FileSearchHomePage> createState() => _FileSearchHomePageState();
}

class _FileSearchHomePageState extends State<FileSearchHomePage> {
  final _ctrl = TextEditingController();
  List<FileResult> _results = [];
  bool _searching = false;
  String _typeFilter = '全部';
  String _sizeFilter = '不限';
  List<String> _history = [];

  final _allFiles = [
    FileResult(name: '项目报告.docx', path: '~/Documents/工作/', size: '2.5MB', type: '文档', modified: '2024-01-15'),
    FileResult(name: '演示文稿.pptx', path: '~/Documents/工作/', size: '5.1MB', type: '文档', modified: '2024-01-10'),
    FileResult(name: '数据表格.xlsx', path: '~/Documents/数据/', size: '1.2MB', type: '文档', modified: '2024-01-12'),
    FileResult(name: '照片_2024.jpg', path: '~/Pictures/相册/', size: '3.8MB', type: '图片', modified: '2024-01-08'),
    FileResult(name: '截图_001.png', path: '~/Pictures/截图/', size: '856KB', type: '图片', modified: '2024-01-14'),
    FileResult(name: '会议录音.mp3', path: '~/Music/录音/', size: '12.4MB', type: '音频', modified: '2024-01-09'),
    FileResult(name: '视频教程.mp4', path: '~/Videos/', size: '256MB', type: '视频', modified: '2024-01-05'),
    FileResult(name: '下载文件.zip', path: '~/Downloads/', size: '45.2MB', type: '压缩包', modified: '2024-01-13'),
    FileResult(name: '备份数据.tar', path: '~/Backups/', size: '1.2GB', type: '压缩包', modified: '2024-01-01'),
    FileResult(name: '配置文件.json', path: '~/.config/', size: '4KB', type: '其他', modified: '2024-01-11'),
    FileResult(name: '日志文件.log', path: '~/Logs/', size: '256KB', type: '其他', modified: '2024-01-14'),
    FileResult(name: '源代码.dart', path: '~/Projects/lib/', size: '12KB', type: '代码', modified: '2024-01-15'),
    FileResult(name: '样式表.css', path: '~/Projects/assets/', size: '8KB', type: '代码', modified: '2024-01-14'),
    FileResult(name: '页面.html', path: '~/Projects/web/', size: '5KB', type: '代码', modified: '2024-01-13'),
  ];

  @override
  void initState() { super.initState(); _loadHistory(); }

  Future<void> _loadHistory() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('file_search_history');
    if (d != null) setState(() => _history = List<String>.from(json.decode(d)));
  }

  Future<void> _saveHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('file_search_history', json.encode(_history));
  }

  void _search() {
    final q = _ctrl.text.trim().toLowerCase();
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    if (!_history.contains(q)) { _history.insert(0, q); if (_history.length > 15) _history = _history.sublist(0, 15); _saveHistory(); }
    Future.delayed(const Duration(milliseconds: 500), () {
      var filtered = _allFiles.where((f) => f.name.toLowerCase().contains(q) || f.path.toLowerCase().contains(q)).toList();
      if (_typeFilter != '全部') filtered = filtered.where((f) => f.type == _typeFilter).toList();
      if (_sizeFilter == '大文件') filtered = filtered.where((f) => f.size.contains('MB') || f.size.contains('GB')).toList();
      setState(() { _results = filtered; _searching = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔍 秒级文件搜索'), centerTitle: true),
      body: Column(children: [
        Container(padding: const EdgeInsets.all(12), child: Column(children: [
          TextField(controller: _ctrl, autofocus: true, decoration: InputDecoration(hintText: '搜索文件名或路径...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)), prefixIcon: const Icon(Icons.search), suffixIcon: _ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _ctrl.clear(); setState(() => _results = []); }) : null, contentPadding: const EdgeInsets.symmetric(horizontal: 20)), onSubmitted: (_) => _search()),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['全部', '文档', '图片', '音频', '视频', '压缩包', '代码', '其他'].map((t) => Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(label: Text(t, style: const TextStyle(fontSize: 12)), selected: _typeFilter == t, onSelected: (_) { setState(() => _typeFilter = t); if (_ctrl.text.isNotEmpty) _search(); }, visualDensity: VisualDensity.compact))).toList())),
          const SizedBox(height: 4),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['不限', '大文件'].map((t) => Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(label: Text(t, style: const TextStyle(fontSize: 12)), selected: _sizeFilter == t, onSelected: (_) { setState(() => _sizeFilter = t); if (_ctrl.text.isNotEmpty) _search(); }, visualDensity: VisualDensity.compact))).toList())),
        ])),
        const Divider(height: 1),
        Expanded(child: _searching ? const Center(child: CircularProgressIndicator()) : _ctrl.text.isEmpty ? _buildHistory() : _results.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search_off, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('没有找到匹配文件', style: TextStyle(color: Colors.grey.shade500))])) : _buildResults()),
      ]),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) return const Center(child: Text('输入关键词搜索文件', style: TextStyle(color: Colors.grey)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('搜索历史', style: TextStyle(fontWeight: FontWeight.bold)), TextButton(onPressed: () { setState(() => _history.clear()); _saveHistory(); }, child: const Text('清除'))])),
      Expanded(child: ListView.builder(itemCount: _history.length, itemBuilder: (ctx, i) => ListTile(leading: const Icon(Icons.history), title: Text(_history[i]), onTap: () { _ctrl.text = _history[i]; _search(); }))),
    ]);
  }

  Widget _buildResults() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text('找到 ${_results.length} 个文件', style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: ListView.builder(itemCount: _results.length, itemBuilder: (ctx, i) {
        final f = _results[i];
        final icons = {'文档': Icons.description, '图片': Icons.image, '音频': Icons.audiotrack, '视频': Icons.videocam, '压缩包': Icons.archive, '代码': Icons.code, '其他': Icons.insert_drive_file};
        return ListTile(leading: Icon(icons[f.type] ?? Icons.insert_drive_file, color: Colors.blue), title: Text(f.name), subtitle: Text('${f.path} • ${f.size} • ${f.modified}', style: const TextStyle(fontSize: 12)), onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('打开: ${f.path}${f.name}'), behavior: SnackBarBehavior.floating)));
      })),
    ]);
  }
}
