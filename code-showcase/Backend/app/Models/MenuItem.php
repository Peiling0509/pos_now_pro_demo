<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

use App\Events\MenuUpdated;

class MenuItem extends Model
{
    //protected $table = 'menu_items';

    protected $fillable = [
        'category_item_id',
        'food_code',
        'name',
        'sub_name',
        'price',
        'is_open_price',
        'category_item_id',
        'image',
        'is_available',
        'remarks',
    ];

    protected $casts = [
        'remarks' => 'array',
    ];

    protected function casts(): array
    {
        return [
            'is_open_price' => 'boolean',
            'is_available' => 'boolean',
        ];
    }

    public function options() {
        // utilizing the pivot table 'menu_item_option'
        return $this->belongsToMany(Option::class, 'menu_item_option')
                    ->withPivot('extra_price'); 
    }

    public function categoryItem()
    {
        return $this->belongsTo(CategoryItem::class);
    }

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($menuItem) {
            // Only generate a number if the user left it blank
            if (empty($menuItem->sub_name)) {
                // Find the highest number in the database
                // (We use CAST because the database column is currently a string)
                $maxNumber = self::max(DB::raw('CAST(sub_name AS UNSIGNED)')) ?? 0;
                
                // Add 1 to the highest number
                $menuItem->sub_name = (string) ($maxNumber + 1);
            }
        });
    }

    /**
     * The "booted" method of the model.
     */
    protected static function booted(): void
    {
        // Fires when an item is created OR updated
        static::saved(function ($item) {
            event(new MenuUpdated());
        });

        // Fires when an item is deleted
        static::deleted(function ($item) {
            event(new MenuUpdated());
        });
    }

    // public function categoryItem()
    // {
    //     return $this->belongsTo(CategoryItem::class, 'category_item_id')
    //         ->select(['id', 'category_id', 'name']); // return 'id', 'category_id' and 'name' fields only
    // }

    // public function options()
    // {
    //     return $this->belongsToMany(Option::class, 'menu_item_option')
    //         ->withPivot('extra_price');
    // }

}
