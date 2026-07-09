<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderItemOption;
use App\Models\MenuItem;
use App\Models\MenuItemOption;
use App\Models\Table;
use App\Http\Resources\OrderResource;
use App\Events\TableUpdated;
use DB;

class OrderController extends Controller
{
    /**
     * Display a listing of orders with status.
     */

    public function index(Request $request)
    {
        // Get status from query string, default null (no filter)
        $status = $request->query('status'); // e.g., 'pending', 'served', 'paid'

        // Build query
        $query = Order::with(['orderItems.orderItemOptions.option', 'user']);

        if ($status) {
            $query->where('status', $status);
        }

        $orders = $query->get();

        return response()->json([
            'success' => true,
            'data' => OrderResource::collection($orders),
        ]);
    }

    //Get latest orders
    public function checkNewOrders(Request $request)
    {
        $afterId = $request->after_id ?? 0;

        $orders = Order::where('id', '>', $afterId)
            ->with(['orderItems.orderItemOptions.option', 'user'])
            ->orderBy('id')
            ->get();

        return response()->json([
            'success' => true,
            'data' => OrderResource::collection($orders)
        ]);
    }

    /**
     * Store a new order with items and options, combining identical items.
     */
    public function store(Request $request)
    {
        // 1. Validate request
        $request->validate([
            'table_id' => 'nullable|exists:tables,id',
            'order_type' => 'required|string|in:dine_in,take_away',
            'items' => 'required|array|min:1',
            'items.*.menu_item_id' => 'required|exists:menu_items,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.weight' => 'nullable|numeric|min:0',
            'items.*.remark' => 'nullable',
            'items.*.menu_item_option' => 'nullable',
            'items.*.custom_price' => 'nullable|numeric|min:0', 
        ]);

        DB::beginTransaction();

        try {
            $order = null;

            // 2. CHECK FOR EXISTING ORDER (Usually applies to Dine-In tables)
            if ($request->table_id) {
                // Eager load order items and options so we can check for duplicates
                $order = Order::with('orderItems.orderItemOptions')
                    ->where('table_id', $request->table_id)
                    ->where('status', 'pending') 
                    ->whereDate('created_at', now()->toDateString())
                    ->first();
            }
            
            $padTime = $request->pad_time 
                ? \Carbon\Carbon::parse($request->pad_time) 
                : now();

            // 3. CREATE NEW ORDER IF NOT FOUND
            if (!$order) {
                $order = Order::create([
                    'table_id'   => $request->table_id,
                    'user_id'    => auth()->id(),
                    'status'     => 'pending',
                    'order_type' => $request->order_type, 
                    'total'      => 0,
                    'created_at' => $padTime,
                    'updated_at' => $padTime,
                ]);

                // Initialize an empty collection so our item matching loop doesn't fail
                $order->setRelation('orderItems', collect());

                // Mark table as occupied
                if ($request->table_id) {
                    Table::where('id', $request->table_id)->update(['status' => 'occupied']);
                }
            }

            $newItemsTotal = 0;

            // 4. LOOP ITEMS
            foreach ($request->items as $itemData) {
                $menuItem = MenuItem::find($itemData['menu_item_id']);
                $quantity = $itemData['quantity'];
                $weight   = $itemData['weight'] ?? null;
                $remark   = $itemData['remark'] ?? null;
                
                // Use custom price if provided, otherwise fallback to database price
                $basePrice = isset($itemData['custom_price']) 
                            ? (float) $itemData['custom_price'] 
                            : (float) $menuItem->price;

                // 1. PRE-CALCULATE OPTIONS TOTAL
                $optionIds = $itemData['menu_item_option'] ?? [];
                $optionIds = is_array($optionIds) ? $optionIds : [$optionIds];
                
                // Sort incoming options so that [1, 2] matches [2, 1] perfectly
                $sortedOptionIds = $optionIds;
                sort($sortedOptionIds);
                
                $validOptions = \App\Models\MenuItemOption::where('menu_item_id', $menuItem->id)
                                ->whereIn('option_id', $optionIds)
                                ->get();

                $optionsTotalPerUnit = $validOptions->sum('extra_price');

                // 2. CALCULATE LINE TOTAL (Using the overridden Base Price)
                $lineItemTotal = ($basePrice + $optionsTotalPerUnit) * $quantity;

                // --- CHECK IF IDENTICAL ITEM ALREADY EXISTS ---
                $matchingItem = null;
                
                foreach ($order->orderItems as $existingItem) {
                    if ($existingItem->menu_item_id == $menuItem->id && 
                        $existingItem->remark == $remark && 
                        (float)$existingItem->price == $basePrice &&
                        (float)$existingItem->weight == (float)$weight) {
                        
                        // Extract and sort the options of the existing item
                        $existingOptionIds = $existingItem->orderItemOptions->pluck('option_id')->toArray();
                        sort($existingOptionIds);
                        
                        // Check if the options match perfectly
                        if ($existingOptionIds == $sortedOptionIds) {
                            $matchingItem = $existingItem;
                            break;
                        }
                    }
                }

                if ($matchingItem) {
                    // MERGE: Just increase the quantity and total of the existing line
                    $matchingItem->quantity += $quantity;
                    $matchingItem->total += $lineItemTotal;
                    $matchingItem->save();

                } else {
                    // CREATE: It's a new unique item or variation, create a new line
                    $orderItem = $order->orderItems()->create([
                        'menu_item_id' => $menuItem->id,
                        'quantity'     => $quantity,
                        'weight'       => $weight,
                        'remark'       => $remark,
                        'price'        => $basePrice, //Saves custom price if it was an open price item
                        'total'        => $lineItemTotal,
                    ]);

                    // SAVE OPTIONS
                    foreach ($validOptions as $opt) {
                        $orderItem->orderItemOptions()->create([
                            'option_id'        => $opt->option_id,
                            'additional_price' => $opt->extra_price,
                        ]);
                    }
                    
                    // Push this new item to the loaded relation in case the user 
                    // submitted the exact same item twice in the exact same request array
                    $order->orderItems->push($orderItem->load('orderItemOptions'));
                }

                // Accumulate for the main Order total
                $newItemsTotal += $lineItemTotal;
            }

            // 5. UPDATE ORDER TOTAL
            $order->total = $order->total + $newItemsTotal;
            $order->save();

            DB::commit(); 

            if ($request->table_id) {
                event(new \App\Events\TableUpdated($request->table_id, 'occupied'));
            }

            // Load relations for response
            $order->load('orderItems.orderItemOptions.option');

            return response()->json([
                'success' => true,
                'message' => 'Order processed successfully'
            ], 201);

        } catch (\Exception $e) {

            DB::rollBack();

            return response()->json([
                'success' => false,
                'error'   => $e->getMessage(),
                'trace'   => $e->getTrace(),
            ], 500);
        }
    }

    /**
     * Update the status of an order (e.g., pending -> served -> paid).
     */
    public function updateStatus(Request $request)
    {
        // 1. Validate Input
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'status'   => 'required|in:pending,served,paid', // Strict validation
        ]);

        DB::beginTransaction();

        try {
            // 2. Find Order
            $order = Order::find($request->order_id);
            $newStatus = $request->status;
            $oldStatus = $order->status;

            // ---------------------------------------------------------
            // 3. MERGE LOGIC FOR "SERVED" ORDERS
            // ---------------------------------------------------------
            if ($newStatus === 'served' && $order->table_id) {
                
                // Check if this table ALREADY has a served order waiting to be paid
                $existingServedOrder = Order::where('table_id', $order->table_id)
                    ->where('status', 'served')
                    ->where('id', '!=', $order->id)
                    ->first();

                if ($existingServedOrder) {
                    // 1. Move all items from the current order to the existing order
                    $order->orderItems()->update(['order_id' => $existingServedOrder->id]);

                    // 2. Add the total price to the existing order
                    $existingServedOrder->total += $order->total;
                    $existingServedOrder->save();

                    // 3. Delete this current order (since it is now empty)
                    $order->delete();

                    DB::commit();

                    return response()->json([
                        'success' => true,
                        'message' => "Order merged into existing served order for Table {$order->table_id}",
                        'merged_into_id' => $existingServedOrder->id,
                        'is_merged' => true
                    ], 200);
                }
            }
            // ---------------------------------------------------------

            // 4. Normal Status Update (If no merge happened)
            $order->status = $newStatus;
            $order->save();

            // 5. Handle Specific Status Logic
            // If status becomes 'paid', free the table
            if ($newStatus === 'paid' && $order->table_id) {
                Table::where('id', $order->table_id)->update(['status' => 'available']);
                
                // Optional: Broadcast event to update Flutter UI
                event(new \App\Events\TableUpdated($order->table_id, 'available'));
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => "Order status updated from $oldStatus to $newStatus",
                'is_merged' => false
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update existing order items (Quantity, Remark, Options, Weight, Custom Price).
     */
    public function update(Request $request, $id)
    {
        // 1. Find the order
        $order = Order::find($id);

        if (!$order) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        // 2. Validate request
        $request->validate([
            'items' => 'required|array|min:1',
            'items.*.id' => 'required|exists:order_items,id', 
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.remark' => 'nullable|string',
            'items.*.menu_item_option' => 'nullable',
            'items.*.weight' => 'nullable|numeric|min:0',
            'items.*.custom_price' => 'nullable|numeric|min:0', 
        ]);

        DB::beginTransaction();

        try {
            // 3. Loop through the items provided in the request
            foreach ($request->items as $itemData) {
                
                // Find the specific item within this order
                $orderItem = $order->orderItems()->where('id', $itemData['id'])->first();

                if (!$orderItem) {
                    continue; // Skip if item doesn't belong to this order
                }

                // Update basic fields
                $orderItem->quantity = $itemData['quantity'];
                $orderItem->remark = $itemData['remark'] ?? null;
                
                // If they cleared the weight box, it sends null, which is perfectly fine.
                if (array_key_exists('weight', $itemData)) {
                    $orderItem->weight = $itemData['weight'];
                }

                if (isset($itemData['custom_price'])) {
                    $orderItem->price = (float) $itemData['custom_price'];
                }
                
                // 4. Handle Option Updates (Syncing)
                $orderItem->orderItemOptions()->delete();

                $optionExtraTotal = 0;
                $optionIds = $itemData['menu_item_option'] ?? [];
                $optionIds = is_array($optionIds) ? $optionIds : [$optionIds];

                foreach ($optionIds as $optionId) {
                    if (!$optionId) continue;

                    $menuOption = \App\Models\MenuItemOption::where('menu_item_id', $orderItem->menu_item_id)
                        ->where('option_id', $optionId)
                        ->first();

                    if ($menuOption) {
                        $extra = $menuOption->extra_price;
                        $optionExtraTotal += $extra;

                        $orderItem->orderItemOptions()->create([
                            'option_id'        => $optionId,
                            'additional_price' => $extra,
                        ]);
                    }
                }

                // Update the individual line item's total before saving
                $lineItemTotal = ($orderItem->price + $optionExtraTotal) * $orderItem->quantity;
                $orderItem->total = $lineItemTotal;

                $orderItem->save();
            }

            // 5. Recalculate the Grand Total for the entire Order
            $newTotal = 0;
            
            // Refresh relationships to get the latest data we just saved
            $order->load('orderItems');

            // Simply sum up the perfectly calculated line item totals
            foreach ($order->orderItems as $item) {
                $newTotal += $item->total;
            }

            $order->update(['total' => $newTotal]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Order updated successfully'
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'error'   => $e->getMessage(),
                'trace'   => $e->getTrace(),
            ], 500);
        }
    }

    /**
     * Delete an entire active order and all its items by Table ID.
     */
    public function destroyByTable(Request $request)
    {
        // 1. Validate the Request
        $request->validate([
            'table_id' => 'required|exists:tables,id',
        ]);

        DB::beginTransaction();

        try {
            // 2. Find the active/pending order for this table
            $order = Order::with('orderItems')
                ->where('table_id', $request->table_id)
                ->where('status', 'pending')
                ->first();

            if (!$order) {
                return response()->json([
                    'success' => false,
                    'message' => 'No active order found for this table'
                ], 404);
            }

            // 3. Delete all related options and items
            foreach ($order->orderItems as $item) {
                // Delete options attached to this specific item
                $item->orderItemOptions()->delete();
                // Delete the item itself
                $item->delete();
            }

            // 4. Delete the main order
            $order->delete();

            // 5. Reset the Table Status to 'available'
            Table::where('id', $request->table_id)->update(['status' => 'available']);
            
            // Broadcast the table update event so your frontend (like Flutter) updates in real-time
            event(new \App\Events\TableUpdated($request->table_id, 'available'));

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Order cleared successfully and table is now available',
                'is_empty' => true // Useful flag for the frontend UI
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'error'   => $e->getMessage()
            ], 500);
        }
    }
   /**
     * Remove a specific item via Request body and recalculate total.
     */
   public function destroyOrderItem(Request $request)
    {
        // 1. Validate the Request
        $request->validate([
            'order_id'      => 'required|exists:orders,id',
            'order_item_id' => 'required|exists:order_items,id',
        ]);

        DB::beginTransaction();

        try {
            // 2. Find the Order
            $order = Order::find($request->order_id);

            // 3. Find the specific Item ensuring it belongs to this Order
            $orderItem = $order->orderItems()->where('id', $request->order_item_id)->first();

            if (!$orderItem) {
                return response()->json(['message' => 'Item not found in this order'], 404);
            }

            // 4. Delete the Item and its options
            $orderItem->orderItemOptions()->delete();
            $orderItem->delete();

            // ---------------------------------------------------------
            // Check if order is empty after deletion
            // ---------------------------------------------------------
            if ($order->orderItems()->count() === 0) {
                // Reset Table Status to 'available'
                if ($order->table_id) {
                    Table::where('id', $order->table_id)->update(['status' => 'available']);
                }

                $order->delete();
                
                DB::commit();

                return response()->json([
                    'success' => true,
                    'message' => 'Order deleted completely as it is now empty',
                    'is_empty' => true // Optional flag for frontend to know to remove the order card
                ], 200);
            }
            // ---------------------------------------------------------

            // 5. Recalculate Order Total (Only runs if items still exist)
            // Refresh relationships to ignore the deleted item
            $order->load('orderItems.orderItemOptions');
            
            $newTotal = 0;

            foreach ($order->orderItems as $item) {
                $basePrice = $item->price;
                $optionsPrice = $item->orderItemOptions->sum('additional_price');
                
                $newTotal += ($basePrice + $optionsPrice) * $item->quantity;
            }

            // 6. Update the main Order record
            $order->update(['total' => $newTotal]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Item deleted successfully',
                'is_empty' => false
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display a specific order.
     */
    public function show($id)
    {
        $order = Order::with('orderItems.orderItemOptions.option')->find($id);

        if (!$order) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        return response()->json($order, 200);
    }

    /**
     * Delete an order.
     */
    public function destroy($id)
    {
        $order = Order::find($id);

        if (!$order) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        $order->delete();

        return response()->json(['message' => 'Order deleted successfully'], 200);
    }
}
