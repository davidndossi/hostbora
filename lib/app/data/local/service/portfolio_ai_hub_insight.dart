import 'portfolio_ai_context.dart';

/// One-line hub banner copy + question to prefill AI Manager (local data only).
class HubInsight {
  const HubInsight({
    required this.line,
    required this.suggestedQuestion,
  });

  final String line;
  final String suggestedQuestion;
}

abstract class PortfolioAiHubInsight {
  PortfolioAiHubInsight._();

  static HubInsight forContext(
    PortfolioAiContext ctx, {
    required bool isSw,
    required String Function(num amount) formatMoney,
  }) {
    if (ctx.isRent) {
      return _rent(ctx, isSw: isSw, formatMoney: formatMoney);
    }
    return _bnb(ctx, isSw: isSw, formatMoney: formatMoney);
  }

  static HubInsight _rent(
    PortfolioAiContext ctx, {
    required bool isSw,
    required String Function(num amount) formatMoney,
  }) {
    if (ctx.arrearsTenantCount > 0) {
      return HubInsight(
        line: isSw
            ? '${ctx.arrearsTenantCount} wapangaji wana deni — ${formatMoney(ctx.arrearsTotal.round())}'
            : '${ctx.arrearsTenantCount} tenant${ctx.arrearsTenantCount == 1 ? '' : 's'} in arrears — ${formatMoney(ctx.arrearsTotal.round())}',
        suggestedQuestion:
            isSw ? 'Wapangaji wenye deni?' : 'Any tenants in arrears?',
      );
    }
    if (ctx.maintenanceTasks > 0) {
      return HubInsight(
        line: isSw
            ? 'Matengenezo ${ctx.maintenanceTasks} yamepangwa — angalia orodha'
            : '${ctx.maintenanceTasks} maintenance task${ctx.maintenanceTasks == 1 ? '' : 's'} scheduled',
        suggestedQuestion: isSw
            ? 'Kazi za matengenezo zilizopangwa?'
            : 'What maintenance is scheduled?',
      );
    }
    if (ctx.leasesExpiring30Days > 0) {
      return HubInsight(
        line: isSw
            ? 'Mikataba ${ctx.leasesExpiring30Days} inaisha ndani ya siku 30'
            : '${ctx.leasesExpiring30Days} lease${ctx.leasesExpiring30Days == 1 ? '' : 's'} expiring within 30 days',
        suggestedQuestion: isSw
            ? 'Mikataba inayoisha hivi karibuni?'
            : 'Leases expiring soon?',
      );
    }
    final occ = ctx.occupancyPercent.toStringAsFixed(0);
    return HubInsight(
      line: isSw
          ? 'Ukodishaji $occ% · mapato ${formatMoney(ctx.monthIncome.round())} mwezi huu'
          : '$occ% occupancy · ${formatMoney(ctx.monthIncome.round())} income this month',
      suggestedQuestion: isSw ? 'Muhtasari wa portfolio' : 'Portfolio summary',
    );
  }

  static HubInsight _bnb(
    PortfolioAiContext ctx, {
    required bool isSw,
    required String Function(num amount) formatMoney,
  }) {
    if (ctx.activeBookingsToday > 0 || ctx.checkInsToday > 0) {
      return HubInsight(
        line: isSw
            ? 'Leo: uhifadhi ${ctx.activeBookingsToday}, uingizaji ${ctx.checkInsToday} · mapato ${formatMoney(ctx.monthIncome.round())}'
            : 'Today: ${ctx.activeBookingsToday} active stay${ctx.activeBookingsToday == 1 ? '' : 's'}, ${ctx.checkInsToday} check-in${ctx.checkInsToday == 1 ? '' : 's'} · ${formatMoney(ctx.monthIncome.round())} this month',
        suggestedQuestion: isSw
            ? 'Uhifadhi wa leo na mapato?'
            : "Today's bookings and revenue?",
      );
    }
    return HubInsight(
      line: isSw
          ? '${ctx.monthLabel}: mapato ${formatMoney(ctx.monthIncome.round())} kutoka mali ${ctx.propertyCount}'
          : '${ctx.monthLabel}: ${formatMoney(ctx.monthIncome.round())} across ${ctx.propertyCount} propert${ctx.propertyCount == 1 ? 'y' : 'ies'}',
      suggestedQuestion: isSw ? 'Muhtasari wa portfolio' : 'Portfolio summary',
    );
  }
}
