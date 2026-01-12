import Recipe from '../../model/Recipe';
import RecipeCard from '../../component/RecipeCard';
import { RecipesDetailViewModel } from '../../viewmodel/RecipesDetailViewModel';
import FavoriteTable from '../../service/FavoriteTable';
import { common } from '@kit.AbilityKit';

@Component
export struct FavoritePageDestination {
  private viewModel: RecipesDetailViewModel | null = null;
  @State private bookmarks: Recipe[] = [];
  @State private isLoading: boolean = true;
  private favoriteTable: FavoriteTable | null = null;
  private navPathStack: NavPathStack = new NavPathStack();
  @StorageLink('context') context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    if (!this.context) {
      console.error('Context is not available');
      return;
    }

    this.favoriteTable = new FavoriteTable(this.context);
    this.viewModel = new RecipesDetailViewModel(this.context);

    this.favoriteTable.getCount((count: number) => {
      console.info('Bookmark count:', count);
    });

    this.viewModel.getBookmarkCount((count: number) => {
      console.info('Bookmark count:', count);
    });

    this.viewModel.getBookmarks((result: Recipe[]) => {
      this.bookmarks = result;
      this.isLoading = false;
      console.info('Bookmarks loaded:', result.length);
    });
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('←')
            .fontSize(24)
            .fontColor(Color.White)
            .margin({ right: 8 })
            .onClick(() => {
              this.navPathStack.pop();
            })
          Text('Favorites')
            .fontSize(20)
            .fontWeight(900)
            .fontColor(Color.White)
        }
        .width('100%')
        .padding(12)

        if (this.isLoading) {
          Text('Loading bookmarks...').fontColor(Color.Gray).fontSize(16)
        } else if (this.bookmarks.length === 0) {
          Text('No bookmarks yet.').fontColor(Color.White).fontSize(16)
        } else {
          Scroll() {
            Column() {
              ForEach(this.bookmarks, (recipe: Recipe) => {
                RecipeCard({ recipe });
              }, (recipe: Recipe) => recipe.id)
            }
          }
          .scrollable(ScrollDirection.Vertical)
          .height('85%')
        }
      }
      .backgroundColor(Color.Black)
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
      if (this.viewModel) {
        this.isLoading = true;
        this.viewModel.getBookmarkCount((count: number) => {
          console.info('Bookmark count (show):', count);
        });
        this.viewModel.getBookmarks((result: Recipe[]) => {
          this.bookmarks = result;
          this.isLoading = false;
          console.info('Bookmarks loaded (show):', result.length);
        });
      }
    })
  }
}