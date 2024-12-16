import 'package:flutter/material.dart';
import 'package:poker_tracker/core/presentation/styles/app_colors.dart';
import 'package:poker_tracker/features/game/data/models/player.dart';
import 'package:poker_tracker/features/game/data/models/settlement_state.dart';

class SettlementDialog extends StatefulWidget {
  final Player player;
  final double buyInAmount;
  final String playerName;
  final int currentIndex;
  final int totalPlayers;
  final SettlementState state;
  final double initialAmount;
  final double recommendedAmount;
  final bool isLastPlayer;
  final String playerId;

  const SettlementDialog({
    super.key,
    required this.player,
    required this.buyInAmount,
    required this.playerName,
    required this.currentIndex,
    required this.totalPlayers,
    required this.state,
    required this.initialAmount,
    required this.recommendedAmount,
    required this.isLastPlayer,
    required this.playerId,
  });

  @override
  State<SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends State<SettlementDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.initialAmount == 0
            ? ''
            : widget.initialAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _remainingBalance {
    double cashOut =
        _controller.text.isEmpty ? 0 : (double.tryParse(_controller.text) ?? 0);
    return widget.state.totalPot -
        (widget.state.totalSettled + cashOut - widget.initialAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBuyInsAndLoans(),
                      const SizedBox(height: 16),
                      if (widget.isLastPlayer) _buildRecommendedAmount(),
                      const SizedBox(height: 16),
                      _buildCashOutInput(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${widget.currentIndex + 1}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Settle Player ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '(${widget.currentIndex + 1}/${widget.totalPlayers})',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.playerName,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Pot Balance',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '\$${_remainingBalance.abs().toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: 1 - (_remainingBalance / widget.state.totalPot),
                backgroundColor: AppColors.backgroundLight,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              if (_remainingBalance == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Amount will balance the pot',
                    style: TextStyle(color: AppColors.success, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Rest of the widgets remain unchanged...
  // (Keeping all other methods exactly the same)

  Widget _buildBuyInsAndLoans() {
    return Row(
      children: [
        Expanded(
            child: _buildInfoBox('Buy-ins',
                '\$${widget.buyInAmount.toStringAsFixed(2)} × ${widget.player.buyIns}')),
        const SizedBox(width: 12),
        Expanded(
            child: _buildInfoBox(
                'Loans', '\$${widget.player.loans.toStringAsFixed(2)} × 1')),
      ],
    );
  }

  Widget _buildInfoBox(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedAmount() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Recommended Amount',
                    style: TextStyle(color: AppColors.success, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${widget.recommendedAmount.toStringAsFixed(2)}',
            style: const TextStyle(
                color: AppColors.success,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCashOutInput() {
    final bool isPlayerSettled = widget.state.isPlayerSettled(widget.playerId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cash-out Amount',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundMedium,
            border: Border.all(
                color: isPlayerSettled ? Colors.grey : AppColors.success),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _controller,
            style: TextStyle(
              color: isPlayerSettled ? Colors.grey : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixText: '\$ ',
              prefixStyle: TextStyle(
                color: isPlayerSettled ? Colors.grey : AppColors.success,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              suffixText: _controller.text.isEmpty ? '' : '.00',
              suffixStyle: const TextStyle(color: Colors.grey, fontSize: 24),
              hintText: '0',
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.5),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            readOnly: isPlayerSettled,
            enabled: !isPlayerSettled,
            onChanged: isPlayerSettled
                ? null
                : (value) {
                    setState(() {});
                  },
          ),
        ),
        if (isPlayerSettled)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'This player has already been settled.',
              style: TextStyle(color: AppColors.warning, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.currentIndex > 0)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, {'action': 'prev'}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.backgroundMedium,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
              ),
            if (widget.currentIndex > 0) const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(_controller.text) ?? 0;
                    Navigator.pop(context, {
                      'action': widget.isLastPlayer && widget.state.isBalanced()
                          ? 'finalize'
                          : 'save',
                      'amount': amount
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    widget.isLastPlayer && widget.state.isBalanced()
                        ? 'Settle'
                        : 'Next',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
