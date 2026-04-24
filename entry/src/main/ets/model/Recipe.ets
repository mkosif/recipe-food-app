export type RecipeCategory =
  | 'soup'
  | 'main'
  | 'dessert'
  | 'pastry'
  | 'breakfast'
  | 'salad'
  | 'drink';

export type Difficulty = 'easy' | 'medium' | 'hard';

export interface Ingredient {
  name: string;
  amount: number;
  unit: string;
}

export interface Nutrition {
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
}

export interface RecipeSummary {
  id: string;
  name: string;
  imageSource: string;
  description: string;
  isFavorite: boolean;
}

export default interface Recipe extends RecipeSummary {
  category: RecipeCategory;
  durationMin: number;
  difficulty: Difficulty;
  servings: number;
  ingredients: Ingredient[];
  steps: string[];
  nutrition?: Nutrition;
}
