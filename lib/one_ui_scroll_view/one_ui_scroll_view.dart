import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const double _kExpendedAppBarHeightRatio = 0.381;

class OneUiScrollView extends StatefulWidget {
  OneUiScrollView({
    Key key,
    @required this.expandedTitle,
    @required this.collapsedTitle,
    this.actions,
    this.children = const [],
    this.bottomDivider = const Divider(height: 0),
    this.scrollController,
    this.expandedHeight,
    this.toolbarHeight = kToolbarHeight,
    this.appBarColor,
    this.elevation = 12.0,
  }) : super(key: key) {
    assert(expandedTitle != null);
    assert(collapsedTitle != null);
  }

  final Widget expandedTitle;
  final Widget collapsedTitle;
  final List<Widget> actions;
  final List<Widget> children;
  final Divider bottomDivider;
  final ScrollController scrollController;
  final double expandedHeight;
  final double toolbarHeight;
  final Color appBarColor;
  final double elevation;

  @override
  _OneUiScrollViewState createState() => _OneUiScrollViewState();
}

class _OneUiScrollViewState extends State<OneUiScrollView> with SingleTickerProviderStateMixin {
  ScrollController _scrollController;
  double _expandedHeight;
  Future<void> scrollAnimateToRunning;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _onNotification(ScrollEndNotification notification) {
    final range = _expandedHeight - widget.toolbarHeight;

    if (_scrollController.offset > 0 && _scrollController.offset < range) {
      final double snapOffset = _scrollController.offset / range > 0.5 ? range : 0;

      Future.delayed(Duration.zero, () async {
        if(scrollAnimateToRunning != null) {
          await scrollAnimateToRunning;
        }
        scrollAnimateToRunning = _scrollController.animateTo(
          snapOffset,
          curve: Curves.ease,
          duration: const Duration(milliseconds: 150),
        );
      });
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
      child: Center(child: widget.expandedTitle),
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

  Widget _actions() {
    if(widget.actions == null)
      return Container();
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        padding: EdgeInsets.only(left: 16),
        height: widget.toolbarHeight,
        child: Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: widget.actions,
          ),
        ),
      ),
    );
  }

  List<Widget> _getAppBar(context, innerBoxIsScrolled) {
    return [
      Builder(builder: (context) => SliverOverlapAbsorber(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        sliver: SliverSafeArea(
          top: false,
          sliver: SliverAppBar(
            backgroundColor: widget.appBarColor,
            pinned: true,
            expandedHeight: _expandedHeight,
            toolbarHeight: widget.toolbarHeight,
            elevation: 12,
            flexibleSpace:LayoutBuilder(
              builder: (context, constraints) {
                final expandRatio = _calculateExpandRatio(constraints);
                final animation = AlwaysStoppedAnimation(expandRatio);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _extendedTitle(animation),
                    _collapsedTitle(animation),
                    _actions(),
                  ],
                );
              },
            ),
            bottom: PreferredSize(
              preferredSize: Size.zero,
              child: widget.bottomDivider,
            ),
          ),
        ),
      )),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _expandedHeight = widget.expandedHeight ??
        MediaQuery.of(context).size.height * _kExpendedAppBarHeightRatio;

    final Widget body = Builder(builder: (BuildContext context) => CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (BuildContext context, int i) => widget.children[i],
            childCount: widget.children.length,
          ),
        ),
      ],
    ),
    );

    return SafeArea(
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (overScroll) {
          overScroll.disallowGlow();
          return true;
        },
        child: NotificationListener<ScrollEndNotification>(
          onNotification: _onNotification,
          child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: _getAppBar,
            body: body,
          ),
        ),
      ),
    );
  }
}
