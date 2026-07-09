<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Http\Resources\OrderItemResource;

class OrderResource extends JsonResource
{
     public function toArray($request)
    {
        return [
            'id' => $this->id,
            'table_id' => $this->table_id,
            'order_type' => $this->order_type,
            'total_price' => floatval($this->total),
            'status' => $this->status,
            'staff_name' => $this->user ? $this->user->name : 'Unknown',
            'order_items' => OrderItemResource::collection($this->orderItems),
            'created_at' => $this->created_at->format('Y-m-d H:i:s'),
        ];
    }
}
