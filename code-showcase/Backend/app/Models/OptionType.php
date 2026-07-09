<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OptionType extends Model
{
    protected $table = 'option_types';
    protected $fillable = ['name','sub_name'];
}
