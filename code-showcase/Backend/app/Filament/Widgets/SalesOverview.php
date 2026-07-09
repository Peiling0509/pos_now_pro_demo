<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Carbon\Carbon;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class SalesOverview extends BaseWidget
{
    //THIS KEEPS IT AT THE TOP OF THE DASHBOARD
    protected static ?int $sort = 1;

    protected function getStats(): array
    { 
        $todayRevenue = Order::where('status', 'paid')
            ->whereDate('created_at', Carbon::today())
            ->sum('total');
            
        $todayOrdersCount = Order::where('status', 'paid')
            ->whereDate('created_at', Carbon::today())
            ->count();
            
        $monthRevenue = Order::where('status', 'paid')
            ->whereMonth('created_at', Carbon::now()->month)
            ->whereYear('created_at', Carbon::now()->year)
            ->sum('total');

        return [
            Stat::make(__('resource.today_revenue'), 'RM ' . number_format($todayRevenue, 2))
                ->description(__('resource.total_sales_today'))
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success')
                ->chart([7, 2, 10, 3, 15, 4, 17]),

            Stat::make(__('resource.today_orders'), $todayOrdersCount)
                ->description(__('resource.total_transactions_today'))
                ->descriptionIcon('heroicon-m-shopping-bag')
                ->color('info'),

            Stat::make(__('resource.month_revenue'), 'RM ' . number_format($monthRevenue, 2))
                ->description(__('resource.total_sales_month'))
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('warning'),
        ];
    }
}