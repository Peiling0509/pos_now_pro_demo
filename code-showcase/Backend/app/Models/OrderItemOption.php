<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderItemOption extends Model
{
    protected $table = 'order_item_options';

    // Mass assignable attributes
    protected $fillable = [
        'order_item_id',
        'option_id',
        'additional_price',
    ];

    public function option()
    {
        return $this->belongsTo(Option::class);
    }
    
}
