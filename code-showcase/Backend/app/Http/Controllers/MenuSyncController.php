<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Category;

class MenuSyncController extends Controller
{
    public function index() {

        return response()->json([
            'success' => true,
            'data' => Category::with(['categoryItems.menuItems.options'])->get()
        ], 200);

    }

}
