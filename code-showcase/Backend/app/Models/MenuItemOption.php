<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MenuItemOption extends Model
{
    protected $table = 'menu_item_option';

    protected $fillable = [
        'menu_item_id',
        'option_id',
        'extra_price',
    ];

    public function option()
    {
        return $this->belongsTo(Option::class);
    }

    public function optionType()
    {
        return $this->belongsTo(OptionType::class, 'option_id');
    }

}

