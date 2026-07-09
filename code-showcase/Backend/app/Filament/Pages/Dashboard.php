<?php

namespace App\Filament\Pages;

use Filament\Pages\Dashboard as BaseDashboard;

class Dashboard extends BaseDashboard
{
    public static function getNavigationLabel(): string
    {
        return __('resource.sales'); 
    }

    public static function getModelLabel(): string
    {
        return __('resource.sales'); 
    }


    // This changes the main heading text on the page itself
    public function getHeading(): string|\Illuminate\Contracts\Support\Htmlable
    {
        return __('resource.welcome_to_posnow_backend');
    }
}