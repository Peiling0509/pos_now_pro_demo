<?php

namespace App\Filament\Resources\MenuItemResource\RelationManagers;

use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ImageColumn;

use Filament\Tables\Actions\AttachAction;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Actions\DetachAction;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Select;

use Illuminate\Support\Facades\App;
use Illuminate\Support\Str;

use App\Events\MenuUpdated;

class OptionsRelationManager extends RelationManager
{
    protected static string $relationship = 'options';

    protected static ?string $recordTitleAttribute = 'name';

    public static function getTitle(\Illuminate\Database\Eloquent\Model $ownerRecord, string $pageClass): string
    {
        return __('resource.available_options');
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                TextInput::make('name')
                    ->required()
                    ->maxLength(255),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('name')
            ->columns([
                TextColumn::make('optionType.name')
                    ->sortable()
                    ->label(__('resource.type'))
                    ->formatStateUsing(function (?string $state, $record): ?string {
                        $isChinese = Str::startsWith(App::getLocale(), 'zh');
                        
                        // If Chinese and sub_name exists on the relation, return sub_name
                        if ($isChinese && $record->optionType && !empty($record->optionType->sub_name)) {
                            return $record->optionType->sub_name;
                        }
                        
                        // Otherwise, return the default state (which is optionType.name)
                        return $state; 
                    }),
                
                TextColumn::make('name')
                    ->label(__('resource.option'))
                    ->formatStateUsing(function (?string $state, $record): ?string {
                        $isChinese = Str::startsWith(App::getLocale(), 'zh');
                        
                        // If Chinese and sub_name exists on the record, return sub_name
                        if ($isChinese && !empty($record->sub_name)) {
                            return $record->sub_name;
                        }
                        
                        // Otherwise, return the default state (which is name)
                        return $state; 
                    }),
                
                TextColumn::make('extra_price')
                    ->label(__('resource.price'))
                    ->money('MYR')
                    ->sortable(),
            ])
            ->headerActions([
                AttachAction::make()
                    // 1. ADD THIS HERE: Tell the Action itself to preload the records
                    ->preloadRecordSelect() 
                    ->recordSelectOptionsQuery(fn (Builder $query) => 
                        $query->with('optionType')
                              ->orderBy('option_type_id') // Groups sizes together, sweetness together
                              ->orderBy('id')             // Sorts them Small -> Medium -> Large based on how you created them
                    )

                
                    ->form(fn (AttachAction $action): array => [
                        
                        $action->getRecordSelect()
                            ->options(function () {
                                // Check locale once before the loop for better performance
                                $isChinese = Str::startsWith(App::getLocale(), 'zh');

                                return \App\Models\Option::with('optionType')
                                    ->orderBy('option_type_id')
                                    ->orderBy('id')
                                    ->get()
                                    ->mapWithKeys(function ($option) use ($isChinese) {
                                        
                                        // 1. Get the correct Type name based on locale 
                                        // (with a fallback to 'name' if 'sub_name' is empty)
                                        $type = '';
                                        if ($option->optionType) {
                                            $type = $isChinese && !empty($option->optionType->sub_name) 
                                                ? $option->optionType->sub_name 
                                                : $option->optionType->name;
                                        }
                                        
                                        // 2. Get the correct Option name based on locale
                                        $name = $isChinese && !empty($option->sub_name) 
                                            ? $option->sub_name 
                                            : $option->name;
                                        
                                        // 3. Combine, eg. 'Size - Small' or '尺寸 - 小'
                                        $label = $type ? "{$type} - {$name}" : $name;
                                        
                                        return [$option->id => $label];
                                    });
                            })
                            ->searchable()
                            ->preload(), 
                        
                        TextInput::make('extra_price')
                            ->label(__('resource.price'))
                            ->numeric()
                            ->default(0)
                            ->prefix('RM'),
                    ]),
            ])
           
            ->actions([ 
                EditAction::make()
                    ->modalHeading(fn ($record) => __('filament-actions::edit.single.label') . ' ' . __("resource.{$record->name}"))
                    ->form([
                        TextInput::make('extra_price')
                            ->label(__('resource.price'))
                            ->numeric()
                            ->required()
                            ->prefix('RM'),
                    ])
                    ->after(fn () => event(new MenuUpdated())), 
                
                DetachAction::make()
                    ->after(fn () => event(new MenuUpdated())),
            ]);
    }
}