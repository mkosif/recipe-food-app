import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import Recipe from '../model/Recipe';

interface RecipeFile {
  recipes: Recipe[];
}

export default class RecipeRepository {
  private static instance: RecipeRepository | null = null;
  private cache: Recipe[] | null = null;

  private constructor() {}

  static getInstance(): RecipeRepository {
    if (!RecipeRepository.instance) {
      RecipeRepository.instance = new RecipeRepository();
    }
    return RecipeRepository.instance;
  }

  async loadAll(context: common.UIAbilityContext): Promise<Recipe[]> {
    if (this.cache) {
      return this.cache;
    }
    try {
      const bytes = await context.resourceManager.getRawFileContent('recipes.json');
      const decoder = util.TextDecoder.create('utf-8');
      const text = decoder.decodeToString(bytes);
      const parsed = JSON.parse(text) as RecipeFile;
      this.cache = parsed.recipes.map((r: Recipe): Recipe => {
        r.isFavorite = false;
        return r;
      });
      return this.cache;
    } catch (err) {
      console.error('[RecipeRepository] Failed to load recipes:', JSON.stringify(err));
      this.cache = [];
      return this.cache;
    }
  }

  async findById(context: common.UIAbilityContext, id: string): Promise<Recipe | undefined> {
    const all = await this.loadAll(context);
    return all.find(r => r.id === id);
  }

  async findByCategory(context: common.UIAbilityContext, category: string): Promise<Recipe[]> {
    const all = await this.loadAll(context);
    return all.filter(r => r.category === category);
  }

  async search(context: common.UIAbilityContext, query: string): Promise<Recipe[]> {
    const all = await this.loadAll(context);
    const q = query.trim().toLowerCase();
    if (!q) {
      return all;
    }
    return all.filter(r =>
      r.name.toLowerCase().includes(q) ||
      r.ingredients.some(i => i.name.toLowerCase().includes(q))
    );
  }

  invalidate(): void {
    this.cache = null;
  }
}
