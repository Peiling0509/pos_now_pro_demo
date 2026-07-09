<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    protected $table = 'payments';

    protected $fillable = [
        'order_id', 
        'method', 
        'amount', 
        'tendered_amount', 
        'change_amount',
        'created_at',
        'updated_at'
    ];
    
    // Optional: Relationship back to order
    public function order() {
        return $this->belongsTo(Order::class);
    }
}