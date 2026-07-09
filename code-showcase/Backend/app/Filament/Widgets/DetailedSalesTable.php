<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\User;

use Filament\Tables;
use Filament\Tables\Table;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Actions\Action;
use Filament\Tables\Actions\DeleteAction;
use Filament\Tables\Columns\Summarizers\Sum;
use Filament\Widgets\TableWidget as BaseWidget;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Select;
use Filament\Forms\Get;
use Filament\Support\Exceptions\Halt;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Str;

use Carbon\Carbon;
use Filament\Notifications\Notification;
use Mike42\Escpos\PrintConnectors\NetworkPrintConnector;
use Mike42\Escpos\Printer;

class DetailedSalesTable extends BaseWidget
{
    // THIS PUTS THE TABLE UNDERNEATH THE STATS CARDS
    protected static ?int $sort = 2;

    // Make the table span the entire width of the dashboard
    protected int | string | array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        $isChinese = Str::startsWith(App::getLocale(), 'zh');

        return $table
            ->headerActions([
                Action::make('print_report')
                    ->label(__('resource.print_report'))
                    ->icon('heroicon-m-printer')
                    ->color('warning')
                    ->form([
                        // 1. FORMAT SELECTION
                        Select::make('print_format')
                            ->label(__('resource.print_format') ?? 'Format')
                            ->options([
                                'thermal' => __('resource.thermal_receipt') ?? 'Thermal Printer',
                                'pdf' => __('resource.pdf_document') ?? 'Download PDF',
                            ])
                            ->default('thermal')
                            ->live() // Triggers real-time UI updates
                            ->required(),

                        TextInput::make('report_month')
                            ->label(__('resource.select_month'))
                            ->type('month') 
                            ->default(now()->format('Y-m')) 
                            ->required(),

                        // 2. PRINTER IP (Only visible if Thermal is selected)
                        TextInput::make('printer_ip')
                            ->label(__('resource.printer_ip_address'))
                            ->default('192.168.10.210')
                            ->visible(fn (Get $get) => $get('print_format') === 'thermal') // Hides when PDF is selected
                            ->required(fn (Get $get) => $get('print_format') === 'thermal'),
                    ]) 
                    ->action(function (array $data) {
                        $monthYear = $data['report_month'] ?? now()->format('Y-m');
                        $date = Carbon::createFromFormat('Y-m', $monthYear);

                        // --- GATHER DATA (Used by both Thermal and PDF) ---
                        $totalSales = Order::where('status', 'paid')
                                        ->whereMonth('created_at', $date->month)
                                        ->whereYear('created_at', $date->year)
                                        ->sum('total');

                        $payments = Payment::whereHas('order', function($query) use ($date) {
                                $query->where('status', 'paid')
                                    ->whereMonth('created_at', $date->month)
                                    ->whereYear('created_at', $date->year);
                            })
                            ->select('method', \Illuminate\Support\Facades\DB::raw('SUM(amount) as total_amount'))
                            ->groupBy('method')
                            ->get();

                        $orderItems = OrderItem::with(['menuItem.categoryItem', 'options.optionType'])
                            ->whereHas('order', function($q) use ($date) {
                                $q->where('status', 'paid')
                                ->whereMonth('created_at', $date->month)
                                ->whereYear('created_at', $date->year);
                            })
                            ->get();

                        $categoryItemSummary = [];
                        $totalItems = 0;

                        foreach ($orderItems as $orderItem) {
                            $catItemName = $orderItem->menuItem->categoryItem->name ?? 'UNCATEGORIZED';
                            
                            if (!isset($categoryItemSummary[$catItemName])) {
                                $categoryItemSummary[$catItemName] = [
                                    'quantity' => 0,
                                    'total' => 0
                                ];
                            }
                            
                            $categoryItemSummary[$catItemName]['quantity'] += $orderItem->quantity;
                            $categoryItemSummary[$catItemName]['total'] += $orderItem->total;
                            $totalItems += $orderItem->quantity;
                        }

                        // ==========================================
                        // OUTPUT 1: PDF DOWNLOAD
                        // ==========================================
                        if ($data['print_format'] === 'pdf') {
                            
                            // Check if dompdf is installed
                            if (!class_exists(\Barryvdh\DomPDF\Facade\Pdf::class)) {
                                Notification::make()
                                    ->title('Package Missing')
                                    ->body('Please install barryvdh/laravel-dompdf to use this feature.')
                                    ->danger()->send();
                                throw new Halt();
                            }

                            $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('reports.monthly-sales', [
                                'monthYear' => $monthYear,
                                'totalSales' => $totalSales,
                                'payments' => $payments,
                                'categoryItemSummary' => $categoryItemSummary,
                                'totalItems' => $totalItems,
                            ]);

                            // Stream the download directly to the browser
                            return response()->streamDownload(
                                fn () => print($pdf->output()), 
                                "Sales_Report_{$monthYear}.pdf"
                            );
                        }

                        // ==========================================
                        // OUTPUT 2: THERMAL PRINTER (ESC/POS)
                        // ==========================================
                        try {
                            $connector = new NetworkPrintConnector($data['printer_ip'], 9100);
                            $printer = new Printer($connector);

                            // Helper closures for formatting
                            $printRow = function ($left, $right, $width = 48) use ($printer) {
                                $leftStr = (string)$left;
                                $rightStr = (string)$right;
                                $spaces = $width - strlen($leftStr) - strlen($rightStr);
                                if ($spaces < 1) $spaces = 1; 
                                $printer->text($leftStr . str_repeat(' ', $spaces) . $rightStr . "\n");
                            };

                            $printTableRow = function ($col1, $col2, $col3) use ($printer) {
                                $col1Width = 26; 
                                $col2Width = 6;  
                                $col3Width = 16; 
                                $wrappedCol1 = wordwrap(strtoupper($col1), $col1Width, "\n", true);
                                $col1Lines = explode("\n", $wrappedCol1);

                                foreach ($col1Lines as $index => $line) {
                                    $c1 = str_pad($line, $col1Width, " ", STR_PAD_RIGHT);
                                    if ($index === 0) {
                                        $c2 = str_pad($col2, $col2Width, " ", STR_PAD_LEFT);
                                        $c3 = str_pad($col3, $col3Width, " ", STR_PAD_LEFT);
                                        $printer->text($c1 . $c2 . $c3 . "\n");
                                    } else {
                                        $printer->text($c1 . "\n");
                                    }
                                }
                            };

                            $printDivider = function () use ($printer) {
                                $printer->text(str_repeat('-', 48) . "\n");
                            };

                            // --- START PRINTING ---
                            $printer->initialize();
                            $printer->setJustification(Printer::JUSTIFY_CENTER);
                            $printer->setTextSize(2, 2); 
                            $printer->setEmphasis(true); 
                            $printer->text("JONG'S SEAFOOD\n");
                            
                            $printer->setTextSize(1, 1); 
                            $printer->text("MONTHLY REPORT\n");
                            $printer->setEmphasis(false);
                            $printer->text("Month: " . $monthYear . "\n");
                            $printDivider();

                            $printer->setJustification(Printer::JUSTIFY_LEFT);
                            $printRow("Print Time:", now()->format('d/m/Y H:i'));
                            $printDivider();

                            $printer->setJustification(Printer::JUSTIFY_CENTER);
                            $printer->setEmphasis(true);
                            $printer->text("PAYMENT SUMMARY\n");
                            $printer->setEmphasis(false);
                            
                            $printer->setJustification(Printer::JUSTIFY_LEFT);
                            foreach($payments as $payment) {
                                $printRow(strtoupper($payment->method), "RM " . number_format($payment->total_amount, 2));
                            }
                            $printDivider();

                            $printer->setJustification(Printer::JUSTIFY_CENTER);
                            $printer->setEmphasis(true);
                            $printer->text("SALES BY SUBCATEGORY\n");
                            
                            $printer->setJustification(Printer::JUSTIFY_LEFT);
                            $headerRow = str_pad("Item Group", 26, " ", STR_PAD_RIGHT) . 
                                        str_pad("Qty", 6, " ", STR_PAD_BOTH) . 
                                        str_pad("Total", 16, " ", STR_PAD_LEFT);
                            $printer->text($headerRow . "\n");
                            $printer->setEmphasis(false);
                            
                            foreach($categoryItemSummary as $catItemName => $data) {
                                $printTableRow($catItemName, $data['quantity'], number_format($data['total'], 2));
                            }
                            $printDivider();

                            $printer->setEmphasis(true);
                            $printRow("Total Items Sold:", $totalItems);
                            $printer->setEmphasis(false);
                            $printer->text("\n"); 

                            $printer->setEmphasis(true);
                            $printer->setTextSize(1, 2); 
                            $printRow("Gross Sales:", "RM " . number_format($totalSales, 2));
                            $printer->setTextSize(1, 1); 
                            $printer->setEmphasis(false);
                            
                            $printDivider();
                            $printer->setJustification(Printer::JUSTIFY_CENTER);
                            $printer->text("\n*** END OF REPORT ***\n");

                            $printer->feed(3);
                            $printer->cut();
                            $printer->close();

                            Notification::make()
                                ->title(__('resource.print_successful'))
                                ->body(__('resource.monthly_report_sent'))
                                ->success()
                                ->send();

                        } catch (\Exception $e) { 
                            Notification::make()
                                ->title(__('resource.printer_error'))
                                ->body("Connection failed. Please check the Printer IP and try again. ({$e->getMessage()})")
                                ->danger()
                                ->send();

                            throw new Halt();
                        }
                    }),
            ])
            ->heading(__('resource.detailed_sales_overview'))
            ->description(function (DetailedSalesTable $livewire) {
                $filters = $livewire->getTableFilterState('created_at');
                $from = $filters['created_from'] ?? null;
                $until = $filters['created_until'] ?? null;

                if ($from && $until) {
                    return __('resource.showing_records_from_to', [
                        'from' => \Carbon\Carbon::parse($from)->format('d/m/Y'),
                        'to' => \Carbon\Carbon::parse($until)->format('d/m/Y')
                    ]);
                }

                return __('resource.showing_all_records');
            })
            
            ->query(
                Order::query()->with([
                    'orderItems.menuItem.categoryItem', 
                    'orderItems.options'
                ])->latest()
            )
            ->columns([
                Tables\Columns\TextColumn::make('table_id')
                    ->label(__('resource.table'))
                    ->sortable(),

                // 1. FOOD ITEMS COLUMN
                Tables\Columns\TextColumn::make('food_items') 
                    ->label($isChinese ? '食物' : 'Food Items')
                    ->state(function (Order $record) use ($isChinese): array {
                        return $record->orderItems
                            ->filter(function ($orderItem) {
                                return $orderItem->menuItem?->categoryItem?->category_id == 1;
                            })
                            ->map(function ($orderItem) use ($isChinese) {
                                $menuItem = $orderItem->menuItem;
                                $categoryItem = $menuItem?->categoryItem;
                                if (!$menuItem) return null; 

                                $catItemName = '';
                                if ($categoryItem) {
                                    $catItemName = ($isChinese && !empty($categoryItem->sub_name)) 
                                        ? $categoryItem->sub_name 
                                        : $categoryItem->name;
                                }

                                $itemName = ($isChinese && !empty($menuItem->sub_name)) 
                                    ? $menuItem->sub_name 
                                    : $menuItem->name;

                                if (!empty($catItemName)) {
                                    $itemName = "[$catItemName] " . $itemName;
                                }

                                if ($orderItem->options && $orderItem->options->isNotEmpty()) {
                                    $optionsString = $orderItem->options->map(function ($option) use ($isChinese) {
                                        return ($isChinese && !empty($option->sub_name)) ? $option->sub_name : $option->name;
                                    })->filter()->join(', ');
                                    
                                    if (!empty($optionsString)) {
                                        $itemName .= " ({$optionsString})";
                                    }
                                }
                                return $itemName;
                            })
                            ->filter()
                            ->toArray();
                    })
                    ->listWithLineBreaks()
                    ->bulleted(),

                // 2. BEVERAGE ITEMS COLUMN
                Tables\Columns\TextColumn::make('beverage_items') 
                    ->label($isChinese ? '饮料' : 'Beverages') 
                    ->state(function (Order $record) use ($isChinese): array {
                        return $record->orderItems
                            ->filter(function ($orderItem) {
                                return $orderItem->menuItem?->categoryItem?->category_id == 2;
                            })
                            ->map(function ($orderItem) use ($isChinese) {
                                $menuItem = $orderItem->menuItem;
                                $categoryItem = $menuItem?->categoryItem;
                                if (!$menuItem) return null; 

                                $catItemName = '';
                                if ($categoryItem) {
                                    $catItemName = ($isChinese && !empty($categoryItem->sub_name)) 
                                        ? $categoryItem->sub_name 
                                        : $categoryItem->name;
                                }

                                $itemName = ($isChinese && !empty($menuItem->sub_name)) 
                                    ? $menuItem->sub_name 
                                    : $menuItem->name;

                                if (!empty($catItemName)) {
                                    $itemName = "[$catItemName] " . $itemName;
                                }

                                if ($orderItem->options && $orderItem->options->isNotEmpty()) {
                                    $optionsString = $orderItem->options->map(function ($option) use ($isChinese) {
                                        return ($isChinese && !empty($option->sub_name)) ? $option->sub_name : $option->name;
                                    })->filter()->join(', ');
                                    
                                    if (!empty($optionsString)) {
                                        $itemName .= " ({$optionsString})";
                                    }
                                }
                                return $itemName;
                            })
                            ->filter()
                            ->toArray();
                    })
                    ->listWithLineBreaks()
                    ->bulleted(),
                
                Tables\Columns\TextColumn::make('total')
                    ->label(__('resource.total_amount'))
                    ->money('MYR')
                    ->sortable()
                    ->summarize(
                        Sum::make()
                            ->label(__('resource.total_sales') ?? 'Total Sales')
                            ->money('MYR')
                    ),

                Tables\Columns\TextColumn::make('order_type')
                    ->label(__('resource.order_type'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'dine_in' => 'info',
                        'take_away' => 'warning',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'dine_in' => __('resource.dine_in'),
                        'take_away' => __('resource.take_away'),
                        default => $state,
                    })
                    ->sortable(),

                Tables\Columns\TextColumn::make('status')
                    ->label(__('resource.status'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'served' => 'info',
                        'paid' => 'success',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => __("resource.{$state}"))
                    ->sortable(),

                Tables\Columns\TextColumn::make('created_at')
                    ->label(__('resource.date_and_time'))
                    ->dateTime(__('resource.date_format'))
                    ->sortable(),
            ])
            ->filters([
                Filter::make('created_at')
                    ->form([
                        DatePicker::make('created_from')
                            ->label(__('resource.start_date'))
                            ->default(now()), 
                            
                        DatePicker::make('created_until')
                            ->label(__('resource.end_date'))
                            ->default(now()), 
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['created_from'],
                                fn (Builder $query, $date): Builder => $query->whereDate('created_at', '>=', $date),
                            )
                            ->when(
                                $data['created_until'],
                                fn (Builder $query, $date): Builder => $query->whereDate('created_at', '<=', $date),
                            );
                    })
            ])
            ->actions([               
                DeleteAction::make()
                ->modalHeading(fn (Order $record): string => __('resource.delete_table_order', [
                        'table_id' => $record->table_id,
                    ]))
                ->after(function (Order $record) {
                        if ($record->table_id) {
                            \App\Models\Table::where('id', $record->table_id)->update(['status' => 'available']);
                            event(new \App\Events\TableUpdated($record->table_id, 'available'));
                        }
                        return redirect(request()->header('Referer'));
                    }),
            ]);
    }
}