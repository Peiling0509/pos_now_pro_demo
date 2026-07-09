<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Http\Resources\OrderItemOptionResource;


class OrderItemResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'order_id' => $this->order_id,
            'category_name' => $this->menuItem?->categoryItem?->category?->name ?? 'Uncategorized',
            'food_code' => $this->menuItem?->food_code ?? 'Unknown Item',
            'menu_item_id' => $this->menu_item_id,
            'menu_item_name' => $this->menuItem?->name ?? 'Unknown Item',
            'menu_item_sub_name' => $this->menuItem?->sub_name ?? 'Unknown Item',
            'quantity' => $this->quantity,
            'weight' => $this->weight,
            'remark' => $this->remark,
            'price' => floatval($this->price),
            'total' => floatval($this->total),
            'created_at' => $this->created_at->format('Y-m-d H:i:s'),

            'options' => OrderItemOptionResource::collection($this->orderItemOptions),
        ];
    }
}
