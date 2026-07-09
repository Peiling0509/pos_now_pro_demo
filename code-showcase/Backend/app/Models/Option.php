<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Option extends Model
{
    protected $fillable = [
        'option_type_id',
        'name',
        'sub_name'
    ];

    public function optionType()
    {
        return $this->belongsTo(OptionType::class, 'option_type_id');
    }

    public function menuItems()
    {
        return $this->belongsToMany(MenuItem::class, 'menu_item_option')
                    ->withPivot('extra_price')
                    ->withTimestamps();
    }

}
