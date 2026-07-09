<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Hash;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-users';

    // Translating sidebar labels
    public static function getNavigationLabel(): string
    {
        return __('resource.account_management');
    }

    public static function getModelLabel(): string
    {
        return __('resource.account');
    }

    // SECURITY: Only allow Admins to see this page
    public static function canViewAny(): bool
    {
        return auth()->user()->role === 'admin';
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make(__('resource.account_info'))->schema([
                    Forms\Components\TextInput::make('name')
                        ->label(__('resource.name'))
                        ->required()
                        ->maxLength(255),
                        
                    Forms\Components\TextInput::make('email')
                        ->label(__('resource.email'))
                        ->email()
                        ->required()
                        ->unique(ignoreRecord: true)
                        ->maxLength(255),

                    Forms\Components\Select::make('role')
                        ->label(__('resource.role'))
                        ->options([
                            'admin' => __('resource.role_admin'),
                            'staff' => __('resource.role_staff'),
                        ])
                        ->required()
                        ->default('staff'),
                ])->columns(2),

               Forms\Components\Section::make(__('resource.security_settings'))->schema([
                    Forms\Components\TextInput::make('password')
                        //Dynamically change label based on Create vs Edit
                        ->label(fn (string $context): string => $context === 'create' ? __('resource.password') : __('resource.new_password'))
                        ->password()
                        ->revealable()
                        ->formatStateUsing(fn () => null) 
                        ->dehydrateStateUsing(fn ($state) => Hash::make($state))
                        ->dehydrated(fn ($state) => filled($state))
                        ->required(fn (string $context): bool => $context === 'create'),

                    Forms\Components\TextInput::make('pin_code')
                        //Dynamically change label based on Create vs Edit
                        ->label(fn (string $context): string => $context === 'create' ? __('resource.tablet_pin_code') : __('resource.new_tablet_pin_code'))
                        ->password()
                        ->revealable()
                        ->numeric()
                        ->maxLength(6)
                        //Force the textbox to be empty when loading the Edit page
                        ->formatStateUsing(fn () => null) 
                        ->dehydrateStateUsing(fn ($state) => Hash::make($state))
                        ->dehydrated(fn ($state) => filled($state)),
                ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->label(__('resource.name'))
                    ->searchable()
                    ->sortable(),
                    
                Tables\Columns\TextColumn::make('email')
                    ->label(__('resource.email'))
                    ->searchable(),

                Tables\Columns\TextColumn::make('role')
                    ->label(__('resource.role'))
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'admin' => __('resource.role_admin'),
                        'staff' => __('resource.role_staff'),
                        default => $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'admin' => 'danger', 
                        'staff' => 'info',   
                        default => 'gray',
                    }),

                Tables\Columns\TextColumn::make('created_at')
                    ->label(__('resource.created_at'))
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('role')
                    ->label(__('resource.filter_role'))
                    ->options([
                        'admin' => __('resource.role_admin'),
                        'staff' => __('resource.role_staff'),
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                
                Tables\Actions\DeleteAction::make()
                    ->hidden(function (User $record): bool {
                        if ($record->role !== 'admin') {
                            return false; 
                        }
                        // Removed the static variable to prevent Livewire caching issues
                        return User::where('role', 'admin')->count() <= 1; 
                    })
                    ->before(function (Tables\Actions\DeleteAction $action, User $record) {
                        // SERVER-SIDE BLOCK: Halt the deletion if they are the last admin
                        if ($record->role === 'admin' && User::where('role', 'admin')->count() <= 1) {
                            
                            \Filament\Notifications\Notification::make()
                                ->title(__('resource.admin_protected') ?? 'Action Denied')
                                ->body(__('resource.cannot_delete_all_admins') ?? 'You cannot delete the last remaining admin account.')
                                ->danger()
                                ->send();

                            $action->halt(); // This completely stops the deletion process
                        }
                    }),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make()
                        ->action(function (\Illuminate\Database\Eloquent\Collection $records) {
                            $adminsToDelete = $records->where('role', 'admin')->count();
                            $totalAdmins = User::where('role', 'admin')->count();

                            // Check if this bulk action would delete EVERY admin
                            if ($adminsToDelete > 0 && $adminsToDelete >= $totalAdmins) {
                                
                                // Exclude the first admin in the selection from being deleted
                                $adminToSave = $records->where('role', 'admin')->first();
                                $records = $records->reject(fn ($record) => $record->id === $adminToSave->id);

                                // Notify the user that we intervened
                                \Filament\Notifications\Notification::make()
                                    ->title(__('resource.admin_protected') ?? 'Action Modified')
                                    ->body(__('resource.cannot_delete_all_admins') ?? 'One admin account was retained to prevent system lockout.')
                                    ->warning()
                                    ->send();
                            }

                            // Proceed with deleting the remaining records
                            $records->each->delete();
                        }),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}