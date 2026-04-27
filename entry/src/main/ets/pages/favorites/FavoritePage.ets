import Recipe, { RecipeSummary } from '../../model/Recipe';
import { RecipesDetailViewModel } from '../../viewmodel/RecipesDetailViewModel';
import RecipeRepository from '../../service/RecipeRepository';
import { common } from '@kit.AbilityKit';
import { RecipeListRow } from '../../component/RecipeListRow';

@Component
export struct FavoritePageDestination {
  private viewModel: RecipesDetailViewModel | null = null;
  @State private bookmarks: Recipe[] = [];
  @State private isLoading: boolean = true;
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();
  @StorageLink('context') context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    if (!this.context) {
      return;
    }
    this.viewModel = new RecipesDetailViewModel(this.context);
    this.loadBookmarks();
  }

  private loadBookmarks(): void {
    if (!this.viewModel || !this.context) {
      return;
    }
    const ctx = this.context;
    this.isLoading = true;
    this.viewModel.getBookmarks(async (stubs: RecipeSummary[]) => {
      const repo = RecipeRepository.getInstance();
      const resolved: Recipe[] = [];
      for (const stub of stubs) {
        const full = await repo.findById(ctx, stub.id);
        if (full) {
          full.isFavorite = true;
          resolved.push(full);
        }
      }
      this.bookmarks = resolved;
      this.isLoading = false;
    });
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('←')
            .fontSize(22)
            .fontColor($r('app.color.text_primary'))
            .onClick(() => this.navPathStack.pop())
          Text($r('app.string.nav_favorites'))
            .fontSize(17)
            .fontWeight(900)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .margin({ left: 6 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('92%')
        .padding({ top: 8, bottom: 4 })

        if (this.isLoading) {
          Text($r('app.string.msg_loading_bookmarks'))
            .fontColor($r('app.color.text_secondary'))
            .fontSize(12)
            .margin(16)
        } else if (this.bookmarks.length === 0) {
          Text($r('app.string.msg_no_bookmarks'))
            .fontColor($r('app.color.text_primary'))
            .fontSize(13)
            .margin(16)
        } else {
          List({ space: 6 }) {
            ForEach(this.bookmarks, (recipe: Recipe) => {
              ListItem() {
                RecipeListRow({ recipe: recipe });
              }
              .onClick(() => this.navPathStack.pushPathByName('DetailPage', recipe))
            }, (recipe: Recipe) => recipe.id)
          }
          .width('100%')
          .layoutWeight(1)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
        }
      }
      .backgroundColor($r('app.color.background_primary'))
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Start)
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.navPathStack = context.pathStack;
    })
    .onShown(() => {
      this.loadBookmarks();
    })
  }

}
