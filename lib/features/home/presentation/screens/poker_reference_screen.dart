import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/core/presentation/styles/app_sizes.dart';
import 'package:poker_tracker/core/utils/ui_helpers.dart';

class PokerReferenceScreen extends StatefulWidget {
  const PokerReferenceScreen({super.key});

  @override
  State<PokerReferenceScreen> createState() => _PokerReferenceScreenState();
}

class _PokerReferenceScreenState extends State<PokerReferenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 4; // Poker Reference index

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHandRankingsTab(),
                    _buildOddsTab(),
                    _buildPositionPlayTab(),
                    _buildStrategyTipsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundMedium,
        border: Border(
          top: BorderSide(
            color: AppColors.backgroundMedium,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0, () => context.go('/')),
              _buildNavItem(
                  Icons.group, 'Teams', 1, () => context.go('/teams')),
              _buildNavItem(Icons.bar_chart, 'Game Stats', 2,
                  () => context.go('/analytics')),
              _buildNavItem(Icons.history, 'Game History', 3,
                  () => context.go('/history')),
              _buildNavItem(Icons.tips_and_updates, 'Tips', 4,
                  () => context.go('/poker-reference')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, int index, VoidCallback onTap) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      padding: EdgeInsets.all(16.dp),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: 24.dp,
            ),
          ),
          Text(
            'Poker Reference',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontXL.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.black26,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'Hand Rankings'),
          Tab(text: 'Odds'),
          Tab(text: 'Position Play'),
          Tab(text: 'Strategy'),
        ],
      ),
    );
  }

  Widget _buildHandRankingsTab() {
    final hands = [
      {
        'name': 'Royal Flush',
        'description': 'A, K, Q, J, 10 of the same suit',
        'example': '🂡 🂾 🂽 🂻 🂺',
        'strength': 10
      },
      {
        'name': 'Straight Flush',
        'description': 'Five sequential cards of the same suit',
        'example': '🂩 🂨 🂧 🂦 🂥',
        'strength': 9
      },
      {
        'name': 'Four of a Kind',
        'description': 'Four cards of the same rank',
        'example': '🂡 🂱 🃁 🃑 🂣',
        'strength': 8
      },
      // Add more hands...
    ];

    return ListView.builder(
      padding: EdgeInsets.all(16.dp),
      itemCount: hands.length,
      itemBuilder: (context, index) {
        final hand = hands[index];
        return _buildHandCard(hand);
      },
    );
  }

  Widget _buildHandCard(Map<String, dynamic> hand) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.dp),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12.dp),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.dp),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                hand['strength'].toString(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12.dp),
            Text(
              hand['name'],
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontL.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.dp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hand['description'],
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppSizes.fontM.sp,
                  ),
                ),
                SizedBox(height: 8.dp),
                Text(
                  hand['example'],
                  style: TextStyle(
                    fontSize: 24.dp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOddsTab() {
    final categories = [
      {
        'title': 'Pre-Flop Odds',
        'odds': [
          {'scenario': 'Pocket Pairs', 'probability': '5.9%'},
          {'scenario': 'Suited Connectors', 'probability': '3.3%'},
          {'scenario': 'AK Suited', 'probability': '0.3%'},
        ],
      },
      {
        'title': 'Drawing Odds',
        'odds': [
          {'scenario': 'Flush Draw', 'probability': '35%'},
          {'scenario': 'Open-Ended Straight Draw', 'probability': '31.5%'},
          {'scenario': 'Gutshot Straight Draw', 'probability': '16.5%'},
        ],
      },
      // Add more categories...
    ];

    return ListView.builder(
      padding: EdgeInsets.all(16.dp),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildOddsCategory(category);
      },
    );
  }

  Widget _buildOddsCategory(Map<String, dynamic> category) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.dp),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12.dp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.dp),
            child: Text(
              category['title'],
              style: TextStyle(
                color: AppColors.primary,
                fontSize: AppSizes.fontL.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: category['odds'].length,
            itemBuilder: (context, index) {
              final odd = category['odds'][index];
              return ListTile(
                title: Text(
                  odd['scenario'],
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.fontM.sp,
                  ),
                ),
                trailing: Text(
                  odd['probability'],
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: AppSizes.fontM.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPositionPlayTab() {
    final positions = [
      {
        'position': 'Early Position (UTG)',
        'description': 'Play premium hands only',
        'recommended': ['AA', 'KK', 'QQ', 'AK'],
        'action': 'Tight and aggressive play',
      },
      {
        'position': 'Middle Position',
        'description': 'Slightly wider range than EP',
        'recommended': ['JJ+', 'AQ+', 'KQ suited'],
        'action': 'Mix of tight and loose play',
      },
      // Add more positions...
    ];

    return ListView.builder(
      padding: EdgeInsets.all(16.dp),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final position = positions[index];
        return _buildPositionCard(position);
      },
    );
  }

  Widget _buildPositionCard(Map<String, dynamic> position) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.dp),
      padding: EdgeInsets.all(16.dp),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12.dp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            position['position'],
            style: TextStyle(
              color: AppColors.primary,
              fontSize: AppSizes.fontL.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.dp),
          Text(
            position['description'],
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontM.sp,
            ),
          ),
          SizedBox(height: 12.dp),
          Wrap(
            spacing: 8.dp,
            runSpacing: 8.dp,
            children: (position['recommended'] as List).map((hand) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.dp,
                  vertical: 6.dp,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.dp),
                ),
                child: Text(
                  hand,
                  style: TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyTipsTab() {
    final tips = [
      {
        'category': 'Bankroll Management',
        'tips': [
          'Never play with money you can\'t afford to lose',
          'Set stop-loss and win limits',
          'Only risk 5% of your bankroll in a single session',
        ],
      },
      {
        'category': 'Table Selection',
        'tips': [
          'Look for tables with high average pot size',
          'Avoid tables with multiple strong players',
          'Choose stakes appropriate for your bankroll',
        ],
      },
      // Add more categories...
    ];

    return ListView.builder(
      padding: EdgeInsets.all(16.dp),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final category = tips[index];
        return _buildTipsCategory(category);
      },
    );
  }

  Widget _buildTipsCategory(Map<String, dynamic> category) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.dp),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12.dp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.dp),
            child: Text(
              category['category'],
              style: TextStyle(
                color: AppColors.primary,
                fontSize: AppSizes.fontL.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: category['tips'].length,
            itemBuilder: (context, index) {
              final tip = category['tips'][index];
              return ListTile(
                leading: Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.warning,
                ),
                title: Text(
                  tip,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.fontM.sp,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
