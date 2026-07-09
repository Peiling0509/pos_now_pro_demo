<?php

namespace App\Http\Controllers;

use App\Models\MenuItemOption;
use Illuminate\Http\Request;

class MenuItemOptionController extends Controller
{
    public function index()
    {
         return response()->json([
            'success' => true,
            'data' => MenuItemOption::all(),
        ], 200);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'menu_item_id' => 'required|exists:menu_items,id',
            'option_id'    => 'required|exists:options,id',
            'extra_price'  => 'numeric',
        ]);

        $data = MenuItemOption::create($validated);

        return response()->json(['message' => 'Option added', 'data' => $data], 201);
    }

    public function show(MenuItemOption $menuItemOption)
    {
        return $menuItemOption->load(['menuItem', 'option']);
    }

    public function update(Request $request, MenuItemOption $menuItemOption)
    {
        $validated = $request->validate([
            'menu_item_id' => 'exists:menu_items,id',
            'option_id'    => 'exists:options,id',
            'extra_price'  => 'numeric',
        ]);

        $menuItemOption->update($validated);

        return response()->json(['message' => 'Updated']);
    }

    public function destroy(MenuItemOption $menuItemOption)
    {
        $menuItemOption->delete();
        return response()->json(['message' => 'Deleted']);
    }
}
