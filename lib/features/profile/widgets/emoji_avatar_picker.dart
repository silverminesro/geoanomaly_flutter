import 'package:flutter/material.dart';

class EmojiAvatarPicker extends StatefulWidget {
  final String currentEmoji;
  final Function(String) onEmojiSelected;

  const EmojiAvatarPicker({
    super.key,
    required this.currentEmoji,
    required this.onEmojiSelected,
  });

  @override
  State<EmojiAvatarPicker> createState() => _EmojiAvatarPickerState();
}

class _EmojiAvatarPickerState extends State<EmojiAvatarPicker> {
  final List<String> _categories = [
    'People',
    'Gaming',
    'Animals',
    'Objects',
    'Nature'
  ];
  String _selectedCategory = 'People';

  final Map<String, List<String>> _emojisByCategory = {
    'People': [
      '😀',
      '😃',
      '😄',
      '😁',
      '😊',
      '🙂',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🥸',
      '🤩',
      '🥳',
      '😏',
      '😒',
      '😞',
      '😔',
      '😴',
      '😪',
      '🤤',
      '😴',
      '🥱',
      '😷',
      '🤒',
      '🤕',
      '🤢',
      '🤮',
      '🤧',
      '🥵',
      '🥶',
      '🥴',
      '😵',
      '🤯',
      '🤠',
      '🥺',
      '🙄',
      '😬',
    ],
    'Gaming': [
      '🎮',
      '🎯',
      '🎲',
      '🃏',
      '🎭',
      '🎪',
      '🎨',
      '🎬',
      '🎤',
      '🎧',
      '🎼',
      '🎵',
      '🎶',
      '🎹',
      '🥁',
      '🎷',
      '🎺',
      '🎸',
      '🪕',
      '🎻',
      '🏆',
      '🥇',
      '🥈',
      '🥉',
      '🏅',
      '🎖️',
      '⚽',
      '🏀',
      '🏈',
      '⚾',
      '🥎',
      '🎾',
      '🏐',
      '🏉',
      '🥏',
      '🎱',
      '🪀',
      '🏓',
      '🏸',
      '🏒',
    ],
    'Animals': [
      '🐶',
      '🐱',
      '🐭',
      '🐹',
      '🐰',
      '🦊',
      '🐻',
      '🐼',
      '🐻‍❄️',
      '🐨',
      '🐯',
      '🦁',
      '🐮',
      '🐷',
      '🐽',
      '🐸',
      '🐵',
      '🙈',
      '🙉',
      '🙊',
      '🐒',
      '🐔',
      '🐧',
      '🐦',
      '🐤',
      '🐣',
      '🐥',
      '🦆',
      '🦅',
      '🦉',
      '🦇',
      '🐺',
      '🐗',
      '🐴',
      '🦄',
      '🐝',
      '🪱',
      '🐛',
      '🦋',
      '🐌',
    ],
    'Objects': [
      '⚡',
      '🔥',
      '💎',
      '💍',
      '👑',
      '🎩',
      '🎓',
      '👒',
      '🧢',
      '⛑️',
      '📱',
      '💻',
      '⌨️',
      '🖥️',
      '🖨️',
      '🖱️',
      '🖲️',
      '💽',
      '💾',
      '💿',
      '📷',
      '📸',
      '📹',
      '🎥',
      '📞',
      '☎️',
      '📟',
      '📠',
      '📺',
      '📻',
      '🔑',
      '🗝️',
      '🔨',
      '⛏️',
      '⚒️',
      '🛠️',
      '🗡️',
      '⚔️',
      '🔫',
      '🪃',
    ],
    'Nature': [
      '🌍',
      '🌎',
      '🌏',
      '🌐',
      '🗺️',
      '🗾',
      '🧭',
      '🏔️',
      '⛰️',
      '🌋',
      '🗻',
      '🏕️',
      '🏖️',
      '🏜️',
      '🏝️',
      '🏞️',
      '🏟️',
      '🏛️',
      '🏗️',
      '🧱',
      '🌸',
      '🌺',
      '🌻',
      '🌷',
      '🌹',
      '🥀',
      '🌾',
      '🌿',
      '☘️',
      '🍀',
      '🌱',
      '🌲',
      '🌳',
      '🌴',
      '🌵',
      '🌶️',
      '🥕',
      '🌽',
      '🥒',
      '🥬',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.infinity,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.emoji_emotions, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Choose Avatar Emoji',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current selection
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Text(
                    'Current: ${widget.currentEmoji}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        widget.onEmojiSelected(widget.currentEmoji),
                    child: const Text('Keep Current'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Category tabs
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Emoji grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _emojisByCategory[_selectedCategory]?.length ?? 0,
                itemBuilder: (context, index) {
                  final emoji = _emojisByCategory[_selectedCategory]![index];
                  final isSelected = emoji == widget.currentEmoji;

                  return GestureDetector(
                    onTap: () => widget.onEmojiSelected(emoji),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Random button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _selectRandomEmoji,
                icon: const Icon(Icons.shuffle),
                label: const Text('Random Emoji'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectRandomEmoji() {
    final allEmojis = _emojisByCategory.values.expand((list) => list).toList();
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % allEmojis.length;
    final randomEmoji = allEmojis[randomIndex];
    widget.onEmojiSelected(randomEmoji);
  }
}
