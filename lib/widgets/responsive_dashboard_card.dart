import 'package:flutter/material.dart';

class ResponsiveDashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const ResponsiveDashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive width calculation - SMALLER cards
        double cardWidth;
        if (constraints.maxWidth > 800) {
          // Desktop/Web: smaller fixed width
          cardWidth = 180;
        } else if (constraints.maxWidth > 600) {
          // Tablet: 40% of screen
          cardWidth = constraints.maxWidth * 0.40;
        } else {
          // Mobile: 45% of screen to fit 2 per row
          cardWidth = constraints.maxWidth * 0.45;
        }

        // Ensure minimum and maximum widths - SMALLER
        cardWidth = cardWidth.clamp(140.0, 200.0);

        return SizedBox(
          width: cardWidth,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: onTap != null ? () {
                print('Card tapped: $subtitle');
                onTap!();
              } : null,
              borderRadius: BorderRadius.circular(16),
              splashColor: color.withValues(alpha: 0.1),
              highlightColor: color.withValues(alpha: 0.05),
              child: Container(
                padding: const EdgeInsets.all(12), // Smaller padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: _getIconSize(constraints.maxWidth),
                        color: color,
                      ),
                    ),
                    
                    const SizedBox(height: 10), // Smaller spacing
                    
                    // Title (main value/statistic)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: _getTitleFontSize(constraints.maxWidth),
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 4), // Smaller spacing
                    
                    // Subtitle (description)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: _getSubtitleFontSize(constraints.maxWidth),
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    // Click indicator for interactive cards
                    if (onTap != null) ...[
                      const SizedBox(height: 4),
                      Icon(
                        Icons.touch_app,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Responsive icon size based on screen width - SMALLER
  double _getIconSize(double screenWidth) {
    if (screenWidth > 800) return 28;
    if (screenWidth > 600) return 26;
    return 24;
  }

  // Responsive title font size - SMALLER
  double _getTitleFontSize(double screenWidth) {
    if (screenWidth > 800) return 18;
    if (screenWidth > 600) return 16;
    return 14;
  }

  // Responsive subtitle font size - SMALLER
  double _getSubtitleFontSize(double screenWidth) {
    if (screenWidth > 800) return 12;
    if (screenWidth > 600) return 11;
    return 10;
  }
}

// Extension widget pentru layout-uri de dashboard
class ResponsiveDashboardGrid extends StatelessWidget {
  final List<ResponsiveDashboardCard> cards;
  final double spacing;
  final double runSpacing;

  const ResponsiveDashboardGrid({
    super.key,
    required this.cards,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine number of columns based on screen width - MORE COMPACT
        int crossAxisCount;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 6; // Desktop: 6 columns (very compact)
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 4; // Tablet: 4 columns
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3; // Large mobile: 3 columns
        } else {
          crossAxisCount = 2; // Mobile: 2 columns
        }

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: WrapAlignment.center,
          children: cards,
        );
      },
    );
  }
}

// Quick builder pentru carduri standard
class DashboardCardBuilder {
  static ResponsiveDashboardCard buildUserCard(int userCount, {VoidCallback? onTap}) {
    return ResponsiveDashboardCard(
      icon: Icons.people,
      title: userCount.toString(),
      subtitle: 'Utilizatori',
      color: Colors.blue,
      onTap: onTap,
    );
  }

  static ResponsiveDashboardCard buildRevenueCard(double revenue, {VoidCallback? onTap}) {
    return ResponsiveDashboardCard(
      icon: Icons.attach_money,
      title: '${revenue.toStringAsFixed(0)} RON',
      subtitle: 'Venituri',
      color: Colors.green,
      onTap: onTap,
    );
  }

  static ResponsiveDashboardCard buildCoursesCard(int courseCount, {VoidCallback? onTap}) {
    return ResponsiveDashboardCard(
      icon: Icons.school,
      title: courseCount.toString(),
      subtitle: 'Cursuri',
      color: Colors.orange,
      onTap: onTap,
    );
  }

  static ResponsiveDashboardCard buildAttendanceCard(int attendanceCount, {VoidCallback? onTap}) {
    return ResponsiveDashboardCard(
      icon: Icons.check_circle,
      title: attendanceCount.toString(),
      subtitle: 'Prezențe',
      color: Colors.purple,
      onTap: onTap,
    );
  }

  static ResponsiveDashboardCard buildPaymentsCard(int paymentCount, {VoidCallback? onTap}) {
    return ResponsiveDashboardCard(
      icon: Icons.payment,
      title: paymentCount.toString(),
      subtitle: 'Plăți',
      color: Colors.teal,
      onTap: onTap,
    );
  }

  static ResponsiveDashboardCard buildBarOrdersCard(int orderCount, {VoidCallback? onTap}) {
    return ResponsiveDashboardCard(
      icon: Icons.local_bar,
      title: orderCount.toString(),
      subtitle: 'Comenzi Bar',
      color: Colors.amber,
      onTap: onTap,
    );
  }

  static ResponsiveDashboardCard buildWalletCard(double balance, {VoidCallback? onTap}) {
    return ResponsiveDashboardCard(
      icon: Icons.account_balance_wallet,
      title: '${balance.toStringAsFixed(2)} RON',
      subtitle: 'Wallet Total',
      color: Colors.indigo,
      onTap: onTap,
    );
  }

  static ResponsiveDashboardCard buildCustomCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return ResponsiveDashboardCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
      onTap: onTap,
    );
  }
}
