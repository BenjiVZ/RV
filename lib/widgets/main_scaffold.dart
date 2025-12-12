import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/home_screen.dart';
import '../screens/clients_screen.dart';
import '../screens/history_screen.dart';
import '../screens/tools_screen.dart';
import '../widgets/invoice_form_sheet.dart';

class MainScaffold extends StatefulWidget {
  final int initialPage;

  const MainScaffold({
    super.key,
    this.initialPage = 0,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;
  late PageController _pageController;

  final List<Widget> _pages = [
    const HomeScreen(showNav: false),
    const ClientsScreen(),
    const HistoryScreen(),
    const ToolsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTap(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(isSmallScreen),
      floatingActionButton: _currentIndex == 0 ? _buildFABs(isSmallScreen) : null,
    );
  }

  Widget _buildFABs(bool isSmallScreen) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: isSmallScreen ? 4 : 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left - Floating Totals Card (only when open and has invoices)
              if (provider.isReportOpen && provider.currentInvoices.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: isSmallScreen ? 24 : 32),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                      vertical: isSmallScreen ? 14 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981), // Emerald green
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '\$${provider.grandTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${provider.currentInvoices.length} fact.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Payment breakdown
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Contado
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.attach_money, color: Colors.white, size: isSmallScreen ? 14 : 16),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${provider.totalContado.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 12 : 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Cashea
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade400,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.credit_card, color: Colors.white, size: isSmallScreen ? 14 : 16),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${provider.totalCashea.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 12 : 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // IVOO
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade400,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.smartphone, color: Colors.white, size: isSmallScreen ? 14 : 16),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${provider.totalIvoo.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 12 : 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              // Right FAB - Add invoice (only when open)
              if (provider.isReportOpen)
                FloatingActionButton(
                  heroTag: 'addInvoice',
                  mini: isSmallScreen,
                  onPressed: () => showInvoiceFormSheet(context),
                  backgroundColor: Colors.blue.shade700,
                  child: Icon(Icons.add, color: Colors.white, size: isSmallScreen ? 20 : 24),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 4 : 8,
            vertical: isSmallScreen ? 6 : 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Inicio',
                index: 0,
                color: Colors.blue,
                isSmall: isSmallScreen,
              ),
              _buildNavItem(
                icon: Icons.people_outline,
                label: 'Clientes',
                index: 1,
                color: Colors.teal,
                isSmall: isSmallScreen,
              ),
              _buildNavItem(
                icon: Icons.history,
                label: 'Historial',
                index: 2,
                color: Colors.purple,
                isSmall: isSmallScreen,
              ),
              _buildNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Tools',
                index: 3,
                color: Colors.orange,
                isSmall: isSmallScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required Color color,
    required bool isSmall,
  }) {
    final isActive = _currentIndex == index;

    return InkWell(
      onTap: () => _onNavItemTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 16,
          vertical: isSmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? color : Colors.grey.shade600,
              size: isSmall ? 22 : 26,
            ),
            SizedBox(height: isSmall ? 2 : 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: isSmall ? 9 : 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
