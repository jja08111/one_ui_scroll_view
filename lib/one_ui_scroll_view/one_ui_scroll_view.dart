import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sliver_fill_remaining_box_adapter/sliver_fill_remaining_box_adapter.dart';

const double _kExpendedAppBarHeightRatio = 0.381;

class OneUiScrollView extends StatefulWidget {
  OneUiScrollView({
    Key key,
    @required this.extendedTitle,
    @required this.collapsedTitle,
    this.actions,
    this.children = const [],
    this.bottomDivider = const Divider(height: 0),
    @required this.scrollController,
    this.expandedHeight,
    this.toolbarHeight = 56.0 + 1.0,
    this.backgroundColor,
    this.elevation = 12.0,
  }) : super(key: key) {
    assert(extendedTitle != null);
    assert(collapsedTitle != null);
    assert(scrollController != null);
  }

  final Widget extendedTitle;
  final Widget collapsedTitle;
  final List<Widget> actions;
  final List<Widget> children;
  final Divider bottomDivider;
  final ScrollController scrollController;
  final double expandedHeight;
  final double toolbarHeight;
  final Color backgroundColor;
  final double elevation;

  @override
  _OneUiScrollViewState createState() => _OneUiScrollViewState();
}

class _OneUiScrollViewState extends State<OneUiScrollView> {
  GlobalKey _containerKey = GlobalKey();
  double _expandedHeight;
  double _bottomPadding;

  @override
  void initState() {
    super.initState();
    _bottomPadding = 0;
    widget.children.add(Container(key: _containerKey));

    SchedulerBinding.instance.addPostFrameCallback(_setBottomPadding);
  }

  void _setBottomPadding(Duration duration) {
    final keyContext = _containerKey.currentContext;
    if (_bottomPadding == 0 && keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final pos = box.localToGlobal(Offset.zero);
      final overflowedHeight = (pos.dy - MediaQuery.of(context).size.height);

      double bottomPadding = (_expandedHeight - widget.toolbarHeight);
      if(overflowedHeight > 0) {
        bottomPadding -= overflowedHeight;
        if(bottomPadding < 0)
          bottomPadding = 0;
      }
      assert(bottomPadding > 0);
      setState(() => _bottomPadding = bottomPadding);
    }
  }

  bool _onNotification(ScrollEndNotification scrollEndNotification) {
    final scrollDistance = _expandedHeight - widget.toolbarHeight;
    if(widget.scrollController.offset > 0
        && widget.scrollController.offset < scrollDistance) {
      final double snapOffset = widget.scrollController.offset / scrollDistance > 0.5
          ? scrollDistance : 0;
      Future.microtask(() => widget.scrollController.animateTo(snapOffset,
          duration: const Duration(milliseconds: 150), curve: Curves.easeIn));
    }
    return true;
  }

  double _calculateExpandRatio(BoxConstraints constraints) {
    var expandRatio = (constraints.maxHeight - widget.toolbarHeight)
        / (_expandedHeight - widget.toolbarHeight);

    if (expandRatio > 1.0) expandRatio = 1.0;
    if (expandRatio < 0.0) expandRatio = 0.0;

    return expandRatio;
  }

  Widget _extendedTitle(Animation<double> animation) {
    return FadeTransition(
      opacity: Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: animation,
        curve: Interval(0.3, 1.0, curve: Curves.easeIn),
      )),
      child: Center(child: widget.extendedTitle),
    );
  }

  Widget _collapsedTitle(Animation<double> animation) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
        parent: animation,
        curve: Interval(0.0, 0.7, curve: Curves.easeOut),
      )),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          padding: EdgeInsets.only(left: 16),
          height: widget.toolbarHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: widget.collapsedTitle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _expandedHeight = widget.expandedHeight ??
        MediaQuery.of(context).size.height * _kExpendedAppBarHeightRatio;

    final Widget appBar = SliverAppBar(
      backgroundColor: widget.backgroundColor,
      pinned: true,
      expandedHeight: _expandedHeight,
      toolbarHeight: widget.toolbarHeight,
      elevation: 12,
      //title: Text('취침 알람', style: FontTheme.BoldHeadline5),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio = _calculateExpandRatio(constraints);
          final animation = AlwaysStoppedAnimation(expandRatio);

          return Stack(
            fit: StackFit.expand,
            children: [
              _extendedTitle(animation),
              _collapsedTitle(animation),
            ],
          );
        },
      ),
      actions: widget.actions,
      bottom: PreferredSize(
        preferredSize: Size.zero,
        child: widget.bottomDivider,
      ),
    );

    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (overScroll) {
        overScroll.disallowGlow();
        return true;
      },
      child: NotificationListener<ScrollEndNotification>(
        onNotification: _onNotification,
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          controller: widget.scrollController,
          slivers: [
            appBar,
            SliverList(delegate: SliverChildListDelegate(widget.children)),
            SliverFillRemainingBoxAdapter(child: Container()),
            SliverPadding(padding: EdgeInsets.only(bottom: _bottomPadding)),
          ],
        ),
      ),
    );
  }
}