import { RecipeSummary } from '../model/Recipe'
import FavoriteTable from '../service/FavoriteTable'
import { common } from '@kit.AbilityKit'

export class RecipesDetailViewModel {
  private favoriteTable: FavoriteTable
  private context:common.UIAbilityContext
  constructor(context: common.UIAbilityContext) {
    this.context = context
    this.favoriteTable = new FavoriteTable(this.context, () => {
      console.info('[RecipesDetailVM] FavoriteTable ready')
    })
  }

  getBookmarks(callback: (recipes: RecipeSummary[]) => void): void {
    this.favoriteTable.getAll(callback)
  }

  addBookmark(recipe: RecipeSummary, callback: (success: boolean) => void): void {
    this.favoriteTable.insertFavorite(recipe, callback)
  }

  deleteBookmark(id: string, callback: (success: boolean) => void): void {
    this.favoriteTable.deleteFavorite(id, callback)
  }

  isBookmarked(id: string, callback: (exists: boolean) => void): void {
    this.favoriteTable.isBookmarked(id, callback)
  }

  getBookmarkCount(callback: (count: number) => void): void {
    this.favoriteTable.getCount(callback)
  }

  clearAll(callback: (success: boolean) => void): void {
    this.favoriteTable.clearAll(callback)
  }

  dropTable(callback: (success: boolean) => void): void {
    this.favoriteTable.dropTable(callback)
  }
}
