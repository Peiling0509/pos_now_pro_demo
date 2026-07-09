<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    // Table name (optional)
    protected $table = 'order_items';

    // Mass assignable attributes
    protected $fillable = [
        'order_id',
        'menu_item_id',
        'quantity',
        'weight',
        'price',
        'total',
        'remark',
    ];

    /**
     * Relationship: an order item belongs to an order
     */
    public function order() 
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Relationship: an order item belongs to a menu item
     */
    public function menuItem()
    {
        return $this->belongsTo(MenuItem::class);
    }

    /**
     * Calculate the total price for this order item
     */
    public function totalPrice()
    {
        return $this->quantity * $this->price;
    }


    public function orderItemOptions()
    {
        return $this->hasMany(OrderItemOption::class);
    }

    public function options()
    {
        return $this->belongsToMany(Option::class, 'order_item_options')
                    ->withPivot('additional_price')
                    ->withTimestamps();
    }

    
}
