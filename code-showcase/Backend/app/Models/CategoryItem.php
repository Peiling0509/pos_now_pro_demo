<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CategoryItem extends Model
{
    use HasFactory;

    protected $table = 'category_items';

    protected $fillable = [
        'category_id',
        'name',
        'sub_name'
    ];

    public function menuItems() {
        return $this->hasMany(MenuItem::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}
