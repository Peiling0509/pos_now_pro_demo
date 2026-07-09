<?php

namespace App\Http\Controllers;

use App\Models\CategoryItem;
use Illuminate\Http\Request;

class CategoryItemController extends Controller
{
    /**
     * Display all category items
     */
    public function index()
    {
         return response()->json([
            'success' => true,
            'data' => CategoryItem::all(),
        ], 200);
    }

    /**
     * Store a newly created category item
     */
    public function store(Request $request)
    {
        $request->validate([
            'category_id' => 'required|exists:category,id',
            'name' => 'required|string|max:255',
        ]);

        $item = CategoryItem::create([
            'category_id' => $request->category_id,
            'name' => $request->name,
        ]);

        return response()->json([
            'message' => 'Category item created successfully',
            'data' => $item
        ], 201);
    }

    /**
     * Display a specific category item
     */
    public function show($id)
    {
        $item = CategoryItem::findOrFail($id);
        return response()->json($item);
    }

    /**
     * Update a category item
     */
    public function update(Request $request, $id)
    {
        $request->validate([
            'category_id' => 'sometimes|exists:category,id',
            'name' => 'nullable|string|max:255',
        ]);

        $item = CategoryItem::findOrFail($id);

        $item->update($request->only(['category_id', 'name']));

        return response()->json([
            'message' => 'Category item updated successfully',
            'data' => $item
        ]);
    }

    /**
     * Delete a category item
     */
    public function destroy($id)
    {
        $item = CategoryItem::findOrFail($id);
        $item->delete();

        return response()->json(['message' => 'Category item deleted successfully']);
    }
}
