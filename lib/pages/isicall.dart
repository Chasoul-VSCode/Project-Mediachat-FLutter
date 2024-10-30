import 'package:flutter/material.dart';

class IsiCallPage extends StatelessWidget {
  final bool isDarkMode;
  final String userName;
  final String imageUrl;

  const IsiCallPage({
    Key? key,
    required this.isDarkMode,
    required this.userName,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color accentColor = isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDarkMode ? Colors.black : Colors.blue.shade50,
                    backgroundColor,
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: NetworkImage(imageUrl),
                              child: imageUrl.isEmpty
                                  ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Memanggil...',
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor.withOpacity(0.7),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCallButton(
                        icon: Icons.message,
                        color: accentColor,
                        onPressed: () => Navigator.pop(context),
                      ),
                      _buildCallButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        size: 65,
                        iconSize: 32,
                        onPressed: () => Navigator.pop(context),
                      ),
                      _buildCallButton(
                        icon: Icons.volume_up,
                        color: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 50,
    double iconSize = 24,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: iconSize),
        onPressed: onPressed,
      ),
    );
  }
}
