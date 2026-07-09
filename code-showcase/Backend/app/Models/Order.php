<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    protected $table = 'orders';

    // Mass assignable attributes
    protected $fillable = [
        'table_id',
        'order_type',
        'user_id',
        'status',
        'total',
        'created_at',
        'updated_at'
    ];

    // Default attribute values
    protected $attributes = [
        'status' => 'pending',
        'total' => 0,
    ];

    /**
     * Relationship: An order belongs to a table.
     */
    public function table()
    {
        return $this->belongsTo(Table::class);
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

}
