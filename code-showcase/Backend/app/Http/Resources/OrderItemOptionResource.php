<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderItemOptionResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->option?->id,
            'name' => $this->option?->name, 
            'sub_name' => $this->option?->sub_name,
            'option_type_id' => $this->option?->option_type_id,
            'additional_price' => floatval($this->additional_price),
        ];
    }
}
