<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MenuItemResource\Pages;
use App\Filament\Resources\MenuItemResource\RelationManagers;

use App\Models\MenuItem;
use App\Models\Category;
use App\Models\CategoryItem;

use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Get;
use Filament\Forms\Set;

use Filament\Resources\Resource;

use Filament\Tables;
use Filament\Tables\Table;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ImageColumn;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\FileUpload;

use Illuminate\Support\Facades\App;
use Illuminate\Support\Str;
use Illuminate\Database\Eloquent\Model;


class MenuItemResource extends Resource
{
    protected static ?string $model = MenuItem::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    public static function getNavigationLabel(): string
    {
        return __('resource.menu_items'); 
    }

    public static function getModelLabel(): string
    {
        return __('resource.menu_items');
    }

    public static function getPluralModelLabel(): string
    {
        return __('resource.menu_items');
    }

    public static function form(Form $form): Form
    {
        $isChinese = Str::startsWith(App::getLocale(), 'zh');

        return $form
            ->schema([
                
                // 1. The Parent Category (Food / Beverage)
                Select::make('category_id')
                    ->label(__('resource.main_category'))
                    ->options(function () use ($isChinese) {
                        return Category::all()->mapWithKeys(function ($category) use ($isChinese) {
                            $name = $isChinese && !empty($category->sub_name) ? $category->sub_name : $category->name;
                            return [$category->id => $name];
                        });
                    })
                    ->live()
                    ->required()
                    // Do not save this field to the menu_items database table
                    ->dehydrated(false) 
                    // Populate this field automatically when editing an existing MenuItem
                    ->afterStateHydrated(function (Select $component, ?Model $record) {
                        if ($record && $record->categoryItem) {
                            $component->state($record->categoryItem->category_id);
                        }
                    })
                    ->afterStateUpdated(function (Set $set, Get $get, ?string $state, ?Model $record, string $operation) {
                        // Reset the child select whenever the parent changes
                        $set('category_item_id', null);

                        // If we are editing an existing item, do NOT regenerate the food code
                        if ($operation === 'edit') {
                            return;
                        }

                        if (! $state) {
                            $set('food_code', null);
                            return;
                        }

                        // Generate the Food Code based on the selected Main Category
                        $category = Category::find($state);
                        $isBeverage = $category && $category->name === 'Beverage'; // Adjust to match your DB

                        $prefix = $isBeverage ? 'B' : '';
                        $padLength = $isBeverage ? 2 : 3; 
                        $regex = $isBeverage ? '^B[0-9]+$' : '^[0-9]+$';

                        $latestItem = MenuItem::where('food_code', 'REGEXP', $regex)
                            ->orderByRaw('LENGTH(food_code) DESC') 
                            ->orderBy('food_code', 'desc')
                            ->first();

                        if (! $latestItem) {
                            $set('food_code', $isBeverage ? 'B01' : '001');
                        } else {
                            $numberPart = (int) str_replace('B', '', $latestItem->food_code);
                            $nextNumber = str_pad($numberPart + 1, $padLength, '0', STR_PAD_LEFT);
                            $set('food_code', $prefix . $nextNumber);
                        }
                    }),

                // 2. The Child Category Item (Dynamic based on Parent)
                Select::make('category_item_id')
                    ->label(__('resource.select_category_item')) 
                    ->options(function (Get $get) use ($isChinese) {
                        $categoryId = $get('category_id');
                        
                        if (! $categoryId) {
                            return []; // Return empty if no main category is selected
                        }

                        return CategoryItem::where('category_id', $categoryId)
                            ->get()
                            ->mapWithKeys(function ($item) use ($isChinese) {
                                $name = $isChinese && !empty($item->sub_name) ? $item->sub_name : $item->name;
                                return [$item->id => $name];
                            });
                    })
                    // Disable this field until a main category is selected
                    ->disabled(fn (Get $get) => ! $get('category_id'))
                    ->searchable() 
                    ->preload()
                    ->required(),

                // 3. The Food Code (Auto-populated by category_id)
                TextInput::make('food_code')
                    ->label(__('resource.food_code'))
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->readOnly() 
                    ->helperText(__('resource.food_code_helperText')),

                TextInput::make('name')
                    ->label(__('resource.english_name')) 
                    ->required(),

                TextInput::make('sub_name')
                    ->label(__('resource.chinese_name'))
                    ->required(),

                TextInput::make('price')
                    ->label(__('resource.ori_price')) 
                    ->numeric()
                    ->prefix('RM')
                    ->default(null),

                Forms\Components\Toggle::make('is_open_price')
                    ->label(__('resource.open_price'))
                    ->helperText(__('resource.open_price_helperText'))
                    ->default(false),
                
                FileUpload::make('image')
                    ->label(__('resource.image')) 
                    ->image()
                    ->directory('menu-items')
                    ->disk('public')
                    
                    ->imageResizeMode('contain')
                    ->imageResizeTargetWidth(500) // Limits width to 500px 
                    ->imageResizeTargetHeight(500), // Limits height to 500px
            ]);
    }

    public static function table(Table $table): Table
    {
        $isChinese = Str::startsWith(App::getLocale(), 'zh');

        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query->with('options'))
            ->columns([
                TextColumn::make('food_code')
                    ->label(__('resource.food_code'))
                    ->searchable()
                    ->sortable()
                    ->badge()
                    ->color('success'),

                ImageColumn::make('image')
                    ->label(__('resource.image')), 
                
                TextColumn::make('name')
                    ->searchable()
                    ->label(__('resource.english_name')), 
                
                TextColumn::make('sub_name')
                    ->searchable()
                    ->label(__('resource.chinese_name')), 
                
                TextColumn::make('categoryItem.name')
                    ->label(__('resource.category_item')) 
                    ->formatStateUsing(function (?string $state, $record) use ($isChinese): ?string {
                        // Check if Chinese AND the relation exists AND sub_name is not empty
                        if ($isChinese && $record->categoryItem && !empty($record->categoryItem->sub_name)) {
                            return $record->categoryItem->sub_name;
                        }
                        return $state;
                    })
                    ->searchable()
                    ->sortable(),

                TextColumn::make('categoryItem.category.name')
                    ->label(__('resource.main_category'))
                    ->formatStateUsing(function (?string $state, $record) use ($isChinese): ?string {
                        // Safely traverse the nested relationship: MenuItem -> CategoryItem -> Category
                        if ($isChinese && $record->categoryItem && $record->categoryItem->category && !empty($record->categoryItem->category->sub_name)) {
                            return $record->categoryItem->category->sub_name;
                        }
                        return $state;
                    })
                    ->sortable(),

                TextColumn::make('options.name')
                    ->label(__('resource.available_options'))
                    ->badge()
                    ->color('info')
                    ->formatStateUsing(function (?string $state, $record) use ($isChinese): ?string {
                        if ($isChinese && $state) {
                            // $state here is the original english 'name'. 
                            // We search the already-loaded collection for the matching option to grab its sub_name.
                            $option = $record->options->firstWhere('name', $state);
                            
                            if ($option && !empty($option->sub_name)) {
                                return $option->sub_name;
                            }
                        }
                        return $state; 
                    }) 
                    ->separator(',')
                    ->searchable(),
                    
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            RelationManagers\OptionsRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListMenuItems::route('/'),
            'create' => Pages\CreateMenuItem::route('/create'),
            'edit' => Pages\EditMenuItem::route('/{record}/edit'),
        ];
    }
}
