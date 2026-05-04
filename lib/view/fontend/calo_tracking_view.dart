import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/bmi_service.dart';
import '../../services/nutrition_service.dart';
import '../../user/bmi_record.dart';
import '../../user/food_item.dart';
import '../../user/meal_entry.dart';

class CaloTrackingView extends StatefulWidget {
  const CaloTrackingView({super.key});

  @override
  State<CaloTrackingView> createState() => _CaloTrackingViewState();
}

class _CaloTrackingViewState extends State<CaloTrackingView> {
  static const _accent = Color(0xFFE16D6D);
  static const _accentDeep = Color(0xFF8D1A1A);
  static const _surface = Color(0xFF171717);
  static const _panelBorder = Colors.white10;
  static const _panelShadow = [
    BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 10)),
  ];

  final NutritionService _nutritionService = NutritionService.instance;
  final BmiService _bmiService = BmiService();
  final TextEditingController _searchController = TextEditingController();

  List<FoodItem> _searchResults = const [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Tìm món ăn theo từ khóa và danh mục đã chọn.
  Future<void> _performSearch([String query = '']) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      setState(() {
        _searchResults = const [];
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final items = await _nutritionService.searchFoods(
        normalizedQuery,
        category: _selectedCategory,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _searchResults = items;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  // Kích hoạt tìm kiếm khi người dùng bấm nút search hoặc Enter.
  Future<void> _submitSearch([String? query]) =>
      _performSearch(query ?? _searchController.text);

  // Xóa từ khóa và ẩn kết quả tìm kiếm hiện tại.
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = const [];
      _isSearching = false;
      _hasSearched = false;
    });
  }

  // Dialog tạo món ăn tùy chỉnh từ các nguyên liệu đã chọn.
  Future<void> _showCreateFoodDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final ingredients = <_DishIngredientDraft>[];

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final totals = _calculateDishTotals(ingredients);
              Future<void> submitDish() async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                if (ingredients.isEmpty || totals.totalGrams <= 0) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Please add at least one ingredient'),
                    ),
                  );
                  return;
                }

                await _nutritionService.createCustomFood(
                  name: nameController.text,
                  description: descriptionController.text,
                  caloriesPer100g: totals.caloriesPer100g,
                  proteinPer100g: totals.proteinPer100g,
                  fatPer100g: totals.fatPer100g,
                  carbsPer100g: totals.carbsPer100g,
                );

                if (!mounted) {
                  return;
                }

                Navigator.of(this.context, rootNavigator: true).pop();
                _searchController.clear();
                await _performSearch();
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Custom dish saved')),
                );
              }

              return AlertDialog(
                backgroundColor: const Color(0xFF141414),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: const Text(
                  'Create custom dish',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Dish details'),
                          const SizedBox(height: 10),
                          _buildDialogField(
                            nameController,
                            'Dish name',
                            hintText: 'Example: Chicken salad bowl',
                            isRequired: true,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogField(
                            descriptionController,
                            'Description (optional)',
                            hintText: 'Short note about the dish',
                            maxLines: 2,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (ingredients.isNotEmpty) {
                                unawaited(submitDish());
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final ingredient =
                                        await _showIngredientPicker();
                                    if (ingredient == null) {
                                      return;
                                    }
                                    setDialogState(
                                      () => ingredients.add(ingredient),
                                    );
                                  },
                                  style: _outlineButtonStyle(
                                    radius: 16,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                  ),
                                  label: const Text(
                                    'Add from database',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final ingredient =
                                        await _showManualIngredientDialog();
                                    if (ingredient == null) {
                                      return;
                                    }
                                    setDialogState(
                                      () => ingredients.add(ingredient),
                                    );
                                  },
                                  style: _outlineButtonStyle(
                                    radius: 16,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit_note_rounded),
                                  label: const Text(
                                    'Manual ingredient',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ingredients',
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (ingredients.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Text(
                                'Add ingredients from the database, or create a manual ingredient if it is missing.',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  height: 1.5,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            )
                          else
                            ...ingredients.asMap().entries.map((entry) {
                              final index = entry.key;
                              final ingredient = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ingredient.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${ingredient.grams.toStringAsFixed(0)} g • ${ingredient.calories.toStringAsFixed(0)} kcal',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setDialogState(
                                          () => ingredients.removeAt(index),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dish totals',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _macroChip(
                                      'Weight',
                                      '${totals.totalGrams.toStringAsFixed(0)} g',
                                    ),
                                    _macroChip(
                                      'Cal',
                                      '${totals.totalCalories.toStringAsFixed(0)} kcal',
                                    ),
                                    _macroChip(
                                      'P',
                                      '${totals.totalProtein.toStringAsFixed(1)} g',
                                    ),
                                    _macroChip(
                                      'F',
                                      '${totals.totalFat.toStringAsFixed(1)} g',
                                    ),
                                    _macroChip(
                                      'C',
                                      '${totals.totalCarbs.toStringAsFixed(1)} g',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  totals.totalGrams <= 0
                                      ? 'Nutrition per 100g will be calculated after you add ingredients.'
                                      : 'Per 100g: ${totals.caloriesPer100g.toStringAsFixed(0)} kcal • P ${totals.proteinPer100g.toStringAsFixed(1)} g • F ${totals.fatPer100g.toStringAsFixed(1)} g • C ${totals.carbsPer100g.toStringAsFixed(1)} g',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                    height: 1.5,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: submitDish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentDeep,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      descriptionController.dispose();
    }
  }

  // Bottom sheet chọn nguyên liệu từ danh sách món có sẵn.
  Future<_DishIngredientDraft?> _showIngredientPicker() async {
    final queryController = TextEditingController();
    final gramController = TextEditingController(text: '100');
    List<FoodItem> foods = [];
    String category = 'All';
    bool isLoading = true;

    Future<void> search(StateSetter setSheetState, [String query = '']) async {
      setSheetState(() => isLoading = true);
      final results = await _nutritionService.searchFoods(
        query,
        category: category,
      );
      setSheetState(() {
        foods = results;
        isLoading = false;
      });
    }

    try {
      return await showModalBottomSheet<_DishIngredientDraft>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              void addFirstMatch() {
                final grams = double.tryParse(gramController.text.trim());
                if (grams == null || grams <= 0) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid gram amount'),
                    ),
                  );
                  return;
                }
                if (foods.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('No ingredient matched your search'),
                    ),
                  );
                  return;
                }
                Navigator.of(
                  context,
                ).pop(_DishIngredientDraft.fromFood(foods.first, grams));
              }

              if (isLoading && foods.isEmpty) {
                unawaited(search(setSheetState));
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.82,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add ingredient from database',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: queryController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                        textInputAction: TextInputAction.search,
                        decoration: _inputDecoration(
                          'Search ingredient',
                          Icons.search_rounded,
                          hintText: 'Type ingredient name and press Enter',
                        ),
                        onChanged: (value) => search(setSheetState, value),
                        onSubmitted: (value) => search(setSheetState, value),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: NutritionService.smartCategories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final item =
                                NutritionService.smartCategories[index];
                            final isSelected = item == category;
                            return ChoiceChip(
                              label: Text(
                                item,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setSheetState(() => category = item);
                                search(setSheetState, queryController.text);
                              },
                              selectedColor: _accentDeep,
                              backgroundColor: const Color(0xFF1E1E1E),
                              side: BorderSide(
                                color: isSelected ? _accent : Colors.white24,
                                width: 1.2,
                              ),
                              checkmarkColor: Colors.white,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: gramController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration(
                          'Ingredient amount (g)',
                          Icons.scale_rounded,
                          hintText: 'Press Enter to add first result',
                        ),
                        onSubmitted: (_) => addFirstMatch(),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: _accent,
                                ),
                              )
                            : foods.isEmpty
                            ? Center(
                                child: Text(
                                  'No ingredient found. Use manual ingredient instead.',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: foods.length,
                                itemBuilder: (context, index) {
                                  final food = foods[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        food.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '${food.category} • ${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      trailing: IconButton(
                                        onPressed: () {
                                          final grams = double.tryParse(
                                            gramController.text.trim(),
                                          );
                                          if (grams == null || grams <= 0) {
                                            ScaffoldMessenger.of(
                                              this.context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please enter a valid gram amount',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          Navigator.of(context).pop(
                                            _DishIngredientDraft.fromFood(
                                              food,
                                              grams,
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.add_circle_rounded,
                                          color: _accent,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      queryController.dispose();
      gramController.dispose();
    }
  }

  // Dialog nhập tay nguyên liệu khi không có trong dữ liệu mẫu.
  Future<_DishIngredientDraft?> _showManualIngredientDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final gramController = TextEditingController(text: '100');
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final fatController = TextEditingController();
    final carbsController = TextEditingController();

    try {
      return await showDialog<_DishIngredientDraft>(
        context: context,
        builder: (context) {
          void submitManualIngredient() {
            if (!formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              _DishIngredientDraft(
                name: nameController.text.trim(),
                grams: double.parse(gramController.text.trim()),
                caloriesPer100g: double.parse(caloriesController.text.trim()),
                proteinPer100g: double.parse(proteinController.text.trim()),
                fatPer100g: double.parse(fatController.text.trim()),
                carbsPer100g: double.parse(carbsController.text.trim()),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF141414),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Manual ingredient',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogField(
                      nameController,
                      'Ingredient name',
                      hintText: 'Example: Avocado',
                      isRequired: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      gramController,
                      'Amount (g)',
                      hintText: 'Example: 80',
                      isRequired: true,
                      isNumber: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      caloriesController,
                      'Calories / 100g',
                      hintText: 'Example: 160',
                      isRequired: true,
                      isNumber: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      proteinController,
                      'Protein / 100g',
                      hintText: 'Example: 2.0',
                      isRequired: true,
                      isNumber: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      fatController,
                      'Fat / 100g',
                      hintText: 'Example: 15.0',
                      isRequired: true,
                      isNumber: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(
                      carbsController,
                      'Carbs / 100g',
                      hintText: 'Example: 8.5',
                      isRequired: true,
                      isNumber: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submitManualIngredient(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: submitManualIngredient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      nameController.dispose();
      gramController.dispose();
      caloriesController.dispose();
      proteinController.dispose();
      fatController.dispose();
      carbsController.dispose();
    }
  }

  _DishTotals _calculateDishTotals(List<_DishIngredientDraft> ingredients) {
    double grams = 0;
    double calories = 0;
    double protein = 0;
    double fat = 0;
    double carbs = 0;

    for (final item in ingredients) {
      grams += item.grams;
      calories += item.calories;
      protein += item.protein;
      fat += item.fat;
      carbs += item.carbs;
    }

    return _DishTotals(
      totalGrams: grams,
      totalCalories: calories,
      totalProtein: protein,
      totalFat: fat,
      totalCarbs: carbs,
    );
  }

  // Bottom sheet thêm món đã chọn vào nhật ký ăn hôm nay.
  Future<void> _showAddFoodSheet(FoodItem food) async {
    String selectedMeal = 'Breakfast';
    double grams = 100;
    final gramsController = TextEditingController(text: '100');

    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              void syncGrams(double value) {
                final safe = value < 1 ? 1.0 : value;
                setSheetState(() {
                  grams = safe;
                  gramsController.text = safe.toStringAsFixed(
                    safe.truncateToDouble() == safe ? 0 : 1,
                  );
                });
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if ((food.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          food.description!,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                            height: 1.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _macroChip(
                            'Cal',
                            '${food.caloriesFor(grams).toStringAsFixed(0)} kcal',
                          ),
                          _macroChip(
                            'P',
                            '${food.proteinFor(grams).toStringAsFixed(1)} g',
                          ),
                          _macroChip(
                            'F',
                            '${food.fatFor(grams).toStringAsFixed(1)} g',
                          ),
                          _macroChip(
                            'C',
                            '${food.carbsFor(grams).toStringAsFixed(1)} g',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        initialValue: selectedMeal,
                        dropdownColor: _surface,
                        decoration: _inputDecoration(
                          'Meal type',
                          Icons.restaurant_menu_rounded,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                        items: const ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                            .map(
                              (meal) => DropdownMenuItem(
                                value: meal,
                                child: Text(meal),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setSheetState(() => selectedMeal = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: gramsController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration(
                          'Amount (g)',
                          Icons.scale_rounded,
                          hintText: 'Press Enter to add this food',
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null) {
                            setSheetState(
                              () => grams = parsed < 1 ? 1 : parsed,
                            );
                          }
                        },
                        onFieldSubmitted: (_) async {
                          final value = double.tryParse(
                            gramsController.text.trim(),
                          );
                          if (value == null || value <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a valid gram amount',
                                ),
                              ),
                            );
                            return;
                          }

                          await _nutritionService.addMealEntry(
                            food: food,
                            grams: value,
                            mealType: selectedMeal,
                          );

                          if (!mounted) {
                            return;
                          }

                          Navigator.of(this.context).pop();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${food.name} added to $selectedMeal',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _gramButton(
                              label: '-5g',
                              onTap: () => syncGrams(grams - 5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _gramButton(
                              label: '+5g',
                              onTap: () => syncGrams(grams + 5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _gramButton(
                              label: '+10g',
                              onTap: () => syncGrams(grams + 10),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _gramButton(
                              label: '+50g',
                              onTap: () => syncGrams(grams + 50),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final value = double.tryParse(
                              gramsController.text.trim(),
                            );
                            if (value == null || value <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a valid gram amount',
                                  ),
                                ),
                              );
                              return;
                            }

                            await _nutritionService.addMealEntry(
                              food: food,
                              grams: value,
                              mealType: selectedMeal,
                            );

                            if (!mounted) {
                              return;
                            }

                            Navigator.of(this.context).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${food.name} added to $selectedMeal',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentDeep,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Add to daily plan',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      gramsController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealStream = _nutritionService.getTodayMealEntriesStream();
    final bmiStream = _bmiService.getLatestRecordStream();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Calo Tracking',
          style: TextStyle(
            color: Color.fromARGB(255, 215, 215, 215),
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accentDeep,
        foregroundColor: Colors.white,
        onPressed: _showCreateFoodDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create dish',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
      ),
      body: mealStream == null
          ? _buildNotSignedIn()
          : SafeArea(
              child: StreamBuilder<BmiRecord?>(
                stream: bmiStream,
                builder: (context, bmiSnapshot) {
                  final latestRecord = bmiSnapshot.data;

                  return StreamBuilder<List<MealEntry>>(
                    stream: mealStream,
                    builder: (context, mealSnapshot) {
                      final entries = mealSnapshot.data ?? const <MealEntry>[];

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                12,
                                20,
                                10,
                              ),
                              child: Column(
                                children: [
                                  _buildSummaryCard(entries, latestRecord),
                                  const SizedBox(height: 18),
                                  _buildSearchCard(),
                                ],
                              ),
                            ),
                          ),
                          _buildSearchResults(),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                10,
                                20,
                                10,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.restaurant_rounded,
                                    color: _accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Today\'s menu',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Poppins',
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (entries.isEmpty)
                            SliverToBoxAdapter(child: _buildEmptyDiary())
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildMealEntryCard(entries[index]),
                                childCount: entries.length,
                              ),
                            ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 110),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  // Giao diện thay thế khi người dùng chưa đăng nhập.
  Widget _buildNotSignedIn() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: _panelDecoration(radius: 24),
        child: const Text(
          'Please sign in to search foods, create custom dishes, and save your meal plan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            height: 1.6,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  // Khối tổng quan calories, macros và độ lệch so với TDEE.
  Widget _buildSummaryCard(List<MealEntry> entries, BmiRecord? latestRecord) {
    final totalCalories = entries.fold<double>(
      0,
      (total, item) => total + item.calories,
    );
    final totalProtein = entries.fold<double>(
      0,
      (total, item) => total + item.protein,
    );
    final totalFat = entries.fold<double>(0, (total, item) => total + item.fat);
    final totalCarbs = entries.fold<double>(
      0,
      (total, item) => total + item.carbs,
    );
    final balance = latestRecord == null
        ? null
        : totalCalories - latestRecord.tdee;
    final weeklyKgChange = balance == null ? null : (balance * 7) / 7700;
    final balanceColor = _balanceColor(balance);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _heroDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Daily nutrition dashboard',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${totalCalories.toStringAsFixed(0)} kcal consumed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entries.isEmpty
                          ? 'Start by searching food below or create your own dish.'
                          : '${entries.length} item(s) logged today across your meal plan.',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 13,
                        height: 1.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF09A45), Color(0xFFE16D6D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  'Protein',
                  '${totalProtein.toStringAsFixed(1)} g',
                  Colors.lightBlueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryStat(
                  'Fat',
                  '${totalFat.toStringAsFixed(1)} g',
                  Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryStat(
                  'Carbs',
                  '${totalCarbs.toStringAsFixed(1)} g',
                  Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (latestRecord == null)
            _buildTdeeMissingCard()
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: _panelDecoration(alpha: 0.07, radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Compared with your TDEE ${latestRecord.tdee} kcal/day',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: balanceColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: balanceColor.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          _balanceLabel(balance!),
                          style: TextStyle(
                            color: balanceColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryStat(
                          'Balance',
                          '${balance.abs().toStringAsFixed(0)} kcal',
                          balanceColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryStat(
                          'Est. change',
                          _formatKgChange(weeklyKgChange!),
                          balanceColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _goalSummary(balance, weeklyKgChange),
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 12,
                      height: 1.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Nhắc người dùng tính BMI/TDEE trước khi so sánh calories.
  Widget _buildTdeeMissingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(radius: 20),
      child: Text(
        'Calculate BMI & TDEE first to compare today\'s calories with your maintenance and estimate weight change.',
        style: TextStyle(
          color: Colors.grey.shade300,
          fontSize: 12,
          height: 1.5,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  // Khu vực tìm kiếm gồm ô nhập, lọc danh mục và nút tạo món custom.
  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(radius: 22),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            textInputAction: TextInputAction.search,
            decoration:
                _inputDecoration(
                  'Search food',
                  Icons.search_rounded,
                ).copyWith(
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCategoryFilterButton(),
                        if (_searchController.text.trim().isNotEmpty)
                          IconButton(
                            onPressed: _clearSearch,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white54,
                            ),
                          ),
                        IconButton(
                          onPressed: _submitSearch,
                          icon: const Icon(
                            Icons.search_rounded,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            onChanged: (value) {
              if (value.trim().isEmpty && _hasSearched) {
                _clearSearch();
                return;
              }
              setState(() {});
            },
            onSubmitted: _submitSearch,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter: $_selectedCategory.',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    height: 1.5,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _showCreateFoodDialog,
                style: _outlineButtonStyle(),
                icon: const Icon(Icons.draw_rounded),
                label: const Text(
                  'Custom',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Nút lọc danh mục nằm gọn bên trong thanh tìm kiếm.
  Widget _buildCategoryFilterButton() {
    return PopupMenuButton<String>(
      tooltip: 'choice filter',
      initialValue: _selectedCategory,
      onSelected: (category) {
        setState(() => _selectedCategory = category);
        if (_searchController.text.trim().isNotEmpty) {
          _submitSearch();
        }
      },
      color: const Color(0xFF1E1E1E),
      itemBuilder: (context) => NutritionService.smartCategories
          .map(
            (category) => PopupMenuItem<String>(
              value: category,
              child: Row(
                children: [
                  Icon(
                    category == _selectedCategory
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: category == _selectedCategory
                        ? _accent
                        : Colors.white54,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _accentDeep.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, color: _accent, size: 18),
            const SizedBox(width: 6),
            Text(
              _selectedCategory,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gợi ý nhanh hiển thị ngay dưới ô tìm kiếm.
  // ignore: unused_element
  Widget _buildSearchSuggestions() {
    if (_isSearching) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _solidPanelDecoration(),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
            ),
            SizedBox(width: 10),
            Text(
              'Searching suggestions...',
              style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _solidPanelDecoration(),
        child: const Text(
          'No suggestions found for this keyword.',
          style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
        ),
      );
    }

    final suggestions = _searchResults.take(6).toList();
    return Container(
      width: double.infinity,
      decoration: _solidPanelDecoration(hasShadow: true),
      child: Column(
        children: suggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final food = entry.value;
          final isLast = index == suggestions.length - 1;
          return InkWell(
            onTap: () {
              _searchController.text = food.name;
              _performSearch(food.name);
            },
            borderRadius: BorderRadius.vertical(
              top: index == 0 ? const Radius.circular(18) : Radius.zero,
              bottom: isLast ? const Radius.circular(18) : Radius.zero,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: _accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${food.category} • ${food.caloriesPer100g.toStringAsFixed(0)} kcal • P ${food.proteinPer100g.toStringAsFixed(1)}g • F ${food.fatPer100g.toStringAsFixed(1)}g • C ${food.carbsPer100g.toStringAsFixed(1)}g',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAddFoodSheet(food),
                    icon: const Icon(Icons.add_circle_rounded, color: _accent),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Danh sách kết quả tìm kiếm hiển thị dưới bộ lọc.
  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_isSearching) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator(color: _accent)),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: _solidPanelDecoration(),
            child: const Text(
              'Khong tim thay mon an phu hop voi tu khoa cua ban.',
              style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildFoodCard(_searchResults[index]),
        childCount: _searchResults.length,
      ),
    );
  }

  // Card hiển thị từng món ăn cùng thông tin dinh dưỡng cơ bản.
  Widget _buildFoodCard(FoodItem food) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: _panelDecoration(alpha: 0.05, radius: 20),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food.category,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (food.isCustom)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Custom',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _macroChip(
                '100g',
                '${food.caloriesPer100g.toStringAsFixed(0)} kcal',
              ),
              _macroChip('P', '${food.proteinPer100g.toStringAsFixed(1)} g'),
              _macroChip('F', '${food.fatPer100g.toStringAsFixed(1)} g'),
              _macroChip('C', '${food.carbsPer100g.toStringAsFixed(1)} g'),
            ],
          ),
        ),
        trailing: IconButton(
          onPressed: () => _showAddFoodSheet(food),
          icon: const Icon(Icons.add_circle_rounded, color: _accent, size: 30),
        ),
      ),
    );
  }

  // Card của một món đã được lưu trong nhật ký hôm nay.
  Widget _buildMealEntryCard(MealEntry entry) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.foodName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  entry.mealType,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await _nutritionService.deleteMealEntry(entry.id);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          if ((entry.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.description!,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                height: 1.5,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _macroChip('Amount', '${entry.grams.toStringAsFixed(0)} g'),
              _macroChip('Cal', '${entry.calories.toStringAsFixed(0)} kcal'),
              _macroChip('P', '${entry.protein.toStringAsFixed(1)} g'),
              _macroChip('F', '${entry.fat.toStringAsFixed(1)} g'),
              _macroChip('C', '${entry.carbs.toStringAsFixed(1)} g'),
            ],
          ),
        ],
      ),
    );
  }

  // Trạng thái rỗng khi hôm nay chưa có món nào được lưu.
  Widget _buildEmptyDiary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(22),
      decoration: _panelDecoration(alpha: 0.05, radius: 22),
      child: Text(
        'You have not added any food today. Search and log your first meal to build your dashboard.',
        style: TextStyle(
          color: Colors.grey.shade300,
          height: 1.6,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _summaryStat(String title, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(alpha: 0.08, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Color _balanceColor(double? balance) {
    if (balance == null) {
      return Colors.grey;
    }
    if (balance <= -150) {
      return Colors.greenAccent;
    }
    if (balance >= 150) {
      return const Color(0xFFFFB74D);
    }
    return const Color(0xFF64B5F6);
  }

  String _balanceLabel(double balance) {
    if (balance <= -150) {
      return 'Calorie deficit';
    }
    if (balance >= 150) {
      return 'Calorie surplus';
    }
    return 'Near maintenance';
  }

  String _formatKgChange(double weeklyKgChange) {
    if (weeklyKgChange.abs() < 0.01) {
      return '~0.00 kg/week';
    }
    final sign = weeklyKgChange > 0 ? '+' : '-';
    return '$sign${weeklyKgChange.abs().toStringAsFixed(2)} kg/week';
  }

  String _goalSummary(double balance, double weeklyKgChange) {
    if (balance <= -150) {
      return 'You are under TDEE by about ${balance.abs().toStringAsFixed(0)} kcal today, equivalent to roughly ${weeklyKgChange.abs().toStringAsFixed(2)} kg loss per week if maintained.';
    }
    if (balance >= 150) {
      return 'You are above TDEE by about ${balance.abs().toStringAsFixed(0)} kcal today, equivalent to roughly ${weeklyKgChange.abs().toStringAsFixed(2)} kg gain per week if maintained.';
    }
    return 'Your intake is close to maintenance today, so your weight trend should stay relatively stable if this pattern continues.';
  }

  // Style nút viền dùng lại cho các thao tác phụ trong dialog/bottom sheet.
  ButtonStyle _outlineButtonStyle({
    double radius = 14,
    EdgeInsetsGeometry? padding,
  }) => OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white24),
    padding: padding,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
  );

  // Style panel nền mờ dùng chung cho card và empty state.
  BoxDecoration _panelDecoration({
    double alpha = 0.06,
    double radius = 18,
    bool hasShadow = false,
  }) => BoxDecoration(
    color: Colors.white.withValues(alpha: alpha),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _panelBorder),
    boxShadow: hasShadow ? _panelShadow : null,
  );

  // Style panel nền đặc dùng cho khối gợi ý tìm kiếm.
  BoxDecoration _solidPanelDecoration({bool hasShadow = false}) =>
      BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _panelBorder),
        boxShadow: hasShadow
            ? const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      );

  // Style khối hero gradient ở đầu màn hình theo dõi calories.
  BoxDecoration _heroDecoration() => BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    gradient: const LinearGradient(
      colors: [Color(0xFF591717), Color(0xFF231313), Color(0xFF121212)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(color: Colors.white12),
    boxShadow: _panelShadow,
  );

  Widget _gramButton({required String label, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: _outlineButtonStyle(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _macroChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        '$title  $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.grey.shade300,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
      hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'Poppins'),
      prefixIcon: Icon(icon, color: _accent),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label, {
    String? hintText,
    bool isRequired = false,
    bool isNumber = false,
    int maxLines = 1,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
      onFieldSubmitted: onSubmitted,
      decoration: _inputDecoration(
        label,
        isNumber ? Icons.analytics_outlined : Icons.edit_outlined,
        hintText: hintText,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Required';
        }
        if (isNumber &&
            value != null &&
            value.trim().isNotEmpty &&
            double.tryParse(value.trim()) == null) {
          return 'Invalid';
        }
        return null;
      },
    );
  }
}

class _DishIngredientDraft {
  const _DishIngredientDraft({
    required this.name,
    required this.grams,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
  });

  final String name;
  final double grams;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbsPer100g;

  factory _DishIngredientDraft.fromFood(FoodItem food, double grams) {
    return _DishIngredientDraft(
      name: food.name,
      grams: grams,
      caloriesPer100g: food.caloriesPer100g,
      proteinPer100g: food.proteinPer100g,
      fatPer100g: food.fatPer100g,
      carbsPer100g: food.carbsPer100g,
    );
  }

  double get calories => caloriesPer100g * grams / 100;
  double get protein => proteinPer100g * grams / 100;
  double get fat => fatPer100g * grams / 100;
  double get carbs => carbsPer100g * grams / 100;
}

class _DishTotals {
  const _DishTotals({
    required this.totalGrams,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
  });

  final double totalGrams;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;

  double get caloriesPer100g =>
      totalGrams <= 0 ? 0 : totalCalories / totalGrams * 100;
  double get proteinPer100g =>
      totalGrams <= 0 ? 0 : totalProtein / totalGrams * 100;
  double get fatPer100g => totalGrams <= 0 ? 0 : totalFat / totalGrams * 100;
  double get carbsPer100g =>
      totalGrams <= 0 ? 0 : totalCarbs / totalGrams * 100;
}
