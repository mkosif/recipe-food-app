import { RecipeCategory, Difficulty } from '../model/Recipe';

const CATEGORY_ORDER: RecipeCategory[] = [
  'breakfast',
  'soup',
  'main',
  'salad',
  'pastry',
  'dessert',
  'drink'
];

export function categoryLabel(category: RecipeCategory): Resource {
  switch (category) {
    case 'soup': return $r('app.string.category_soup');
    case 'main': return $r('app.string.category_main');
    case 'dessert': return $r('app.string.category_dessert');
    case 'pastry': return $r('app.string.category_pastry');
    case 'breakfast': return $r('app.string.category_breakfast');
    case 'salad': return $r('app.string.category_salad');
    case 'drink': return $r('app.string.category_drink');
    default: return $r('app.string.category_all');
  }
}

export function difficultyLabel(difficulty: Difficulty): Resource {
  switch (difficulty) {
    case 'easy': return $r('app.string.difficulty_easy');
    case 'medium': return $r('app.string.difficulty_medium');
    case 'hard': return $r('app.string.difficulty_hard');
    default: return $r('app.string.difficulty_easy');
  }
}

export function sortedCategories(present: Set<RecipeCategory>): RecipeCategory[] {
  return CATEGORY_ORDER.filter(c => present.has(c));
}
