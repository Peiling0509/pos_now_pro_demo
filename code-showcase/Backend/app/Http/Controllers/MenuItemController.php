<?php

namespace App\Http\Controllers;

use App\Models\MenuItem;
use Illuminate\Http\Request;

class MenuItemController extends Controller
{
    public function index()
    {
        //return MenuItem::with(['options'])->get();
        
         return response()->json([
            'success' => true,
            'data' => MenuItem::all(),
        ], 200);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_item_id' => 'required|exists:category_items,id',
            'name'            => 'required|string',
            'price'           => 'required|numeric',
            'image'           => 'nullable|string',
            'is_available'    => 'boolean',
            'remarks'         => 'nullable|string',
        ]);

        $item = MenuItem::create($validated);

        return response()->json([
            'message' => 'Menu item created',
            'data'    => $item
        ], 201);
    }

    public function show(MenuItem $menuItem)
    {
        return $menuItem->load(['category', 'options']);
    }

    public function update(Request $request, MenuItem $menuItem)
    {
        $validated = $request->validate([
            'category_item_id' => 'exists:category_items,id',
            'name'            => 'string',
            'price'           => 'numeric',
            'image'           => 'nullable|string',
            'is_available'    => 'boolean',
            'remarks'         => 'nullable|string',
        ]);

        $menuItem->update($validated);

        return response()->json([
            'message' => 'Menu item updated',
            'data'    => $menuItem
        ]);
    }

    public function destroy(MenuItem $menuItem)
    {
        $menuItem->delete();

        return response()->json([
            'message' => 'Menu item deleted'
        ]);
    }
}
