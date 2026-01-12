import Recipe from '../model/Recipe';
import FavoriteTable from '../service/FavoriteTable';
import { common } from '@kit.AbilityKit';

@Component
export struct DetailPageDestination {
  @Prop recipe: Recipe;
  private favoriteTable: FavoriteTable | null = null;
  @State private isLoading: boolean = true;
  @State private currentRecipe: Recipe = this.recipe;
  @State private buttonText: string = '';
  private navPathStack: NavPathStack = new NavPathStack();
  @StorageLink('context') context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    if (!this.context) {
      console.error('Context is not available');
      return;
    }

    this.favoriteTable = new FavoriteTable(this.context);
    this.currentRecipe = this.recipe;
    this.isLoading = false;

    if (this.favoriteTable) {
      this.favoriteTable.getAll((recipes: Recipe[]) => {
        const isInFavorites = recipes.some(item => item.id === this.currentRecipe.id);
        this.currentRecipe.isFavorite = isInFavorites;
        this.buttonText = isInFavorites ? 'Remove Bookmark' : 'Add Bookmark';
      });
    }
  }

  toggleBookmark(): void {
    if (!this.favoriteTable) {
      return;
    }

    if (this.currentRecipe.isFavorite) {
      this.favoriteTable.deleteFavorite(this.currentRecipe.id, (success: boolean) => {
        if (success) {
          this.currentRecipe.isFavorite = false;
          this.buttonText = 'Add Bookmark';
          console.info('Bookmark removed.');
        } else {
          console.error('Failed to remove bookmark.');
        }
      });
    } else {
      const recipeToSave: Recipe = {
        id: this.currentRecipe.id,
        name: this.currentRecipe.name,
        imageSource: this.currentRecipe.imageSource,
        description: this.currentRecipe.description,
        isFavorite: true
      };
      this.favoriteTable.insertFavorite(recipeToSave, (success: boolean) => {
        if (success) {
          this.currentRecipe.isFavorite = true;
          this.buttonText = 'Remove Bookmark';
          if (this.favoriteTable) {
            this.favoriteTable.getCount((count: number) => {
              console.info('Bookmark count:', count);
            });
          }
          console.info('Bookmark added!');
        } else {
          console.error('Failed to add bookmark.');
        }
      });
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row() {
            Text('←')
              .fontSize(24)
              .fontColor(Color.White)
              .margin({ right: 8 })
              .onClick(() => {
                this.navPathStack.pop();
              })
            Text('Detail')
              .fontSize(20)
              .fontWeight(900)
              .fontColor(Color.White)
          }
          .width('100%')
          .padding(12)

          if (this.isLoading) {
            this.buildShimmer();
          } else {
            this.buildContent();
          }
        }
      }
      .scrollable(ScrollDirection.Vertical)
      .backgroundColor(Color.Black)
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.navPathStack = context.pathStack;
    })
  }

  @Builder
  private buildContent() {
    Column() {
      Image($rawfile(this.currentRecipe.imageSource))
        .width('90%')
        .height(150)
        .objectFit(ImageFit.Cover)
        .borderRadius(10)
        .margin({ top: 10, bottom: 10 })
        .alignSelf(ItemAlign.Center)

      Text(this.currentRecipe.name)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .margin({ bottom: 6, left: 12, right: 12 })
        .alignSelf(ItemAlign.Center)

      Text('Description:')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#BBBBBB')
        .margin({ left: 12, right: 12, bottom: 4 })

      Text(this.currentRecipe.description)
        .fontSize(14)
        .fontColor(Color.White)
        .margin({ left: 12, right: 12, bottom: 20 })
        .textAlign(TextAlign.Start)

      Button(this.buttonText)
        .backgroundColor(Color.White)
        .fontColor(Color.Black)
        .margin({ bottom: 10 })
        .fontSize(13)
        .onClick(() => this.toggleBookmark())
    }
  }

  @Builder
  private buildShimmer() {
    Column() {
      Blank()
        .width('90%')
        .height(150)
        .backgroundColor('#333333')
        .borderRadius(10)
        .margin({ top: 10, bottom: 10 })
      Blank().width('60%').height(20).backgroundColor('#444444').margin(12)
      Blank().width('80%').height(14).backgroundColor('#444444').margin({ left: 12, right: 12, bottom: 10 })
      Blank()
        .width('40%')
        .height(40)
        .backgroundColor('#555555')
        .borderRadius(6)
        .margin(10)
    }
    .alignItems(HorizontalAlign.Center)
  }
}