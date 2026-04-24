import { common } from '@kit.AbilityKit';
import Recipe, { RecipeCategory } from '../../model/Recipe';
import RecipeRepository from '../../service/RecipeRepository';
import { categoryLabel, sortedCategories } from '../../util/CategoryUtil';

interface CategoryGroup {
  category: RecipeCategory;
  recipes: Recipe[];
}

@Component
export struct RecipesPageDestination {
  @State private groups: CategoryGroup[] = [];
  @State private isLoading: boolean = true;
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();
  @StorageLink('context') context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    this.loadRecipes();
  }

  private async loadRecipes(): Promise<void> {
    if (!this.context) {
      this.isLoading = false;
      return;
    }
    const all = await RecipeRepository.getInstance().loadAll(this.context);
    const map = new Map<RecipeCategory, Recipe[]>();
    all.forEach(r => {
      const arr = map.get(r.category) ?? [];
      arr.push(r);
      map.set(r.category, arr);
    });
    const ordered = sortedCategories(new Set(map.keys()));
    this.groups = ordered.map(c => {
      const group: CategoryGroup = { category: c, recipes: map.get(c) ?? [] };
      return group;
    });
    this.isLoading = false;
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('←')
            .fontSize(24)
            .fontColor($r('app.color.text_primary'))
            .margin({ right: 8 })
            .onClick(() => this.navPathStack.pop())
          Text($r('app.string.nav_recipes'))
            .fontSize(20)
            .fontWeight(900)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .padding(12)

        if (this.isLoading) {
          Text($r('app.string.msg_loading'))
            .fontColor($r('app.color.text_secondary'))
            .margin(16)
        } else {
          List({ space: 6 }) {
            ForEach(this.groups, (group: CategoryGroup) => {
              ListItemGroup({ header: this.buildHeader(group.category) }) {
                ForEach(group.recipes, (recipe: Recipe) => {
                  ListItem() {
                    this.buildRow(recipe);
                  }
                  .onClick(() => this.navPathStack.pushPathByName('DetailPage', recipe))
                }, (recipe: Recipe) => recipe.id)
              }
            }, (group: CategoryGroup) => group.category)
          }
          .sticky(StickyStyle.Header)
          .width('100%')
          .layoutWeight(1)
        }
      }
      .backgroundColor($r('app.color.background_primary'))
      .height('100%')
      .width('100%')
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
    })
  }

  @Builder
  private buildHeader(category: RecipeCategory) {
    Row() {
      Text(categoryLabel(category))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor($r('app.color.background_primary'))
  }

  @Builder
  private buildRow(recipe: Recipe) {
    Row({ space: 10 }) {
      Image($rawfile(recipe.imageSource))
        .width(44)
        .height(44)
        .borderRadius(22)
        .objectFit(ImageFit.Cover)
      Column({ space: 2 }) {
        Text(recipe.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 6 }) {
          Text(`${recipe.durationMin} `)
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
          Text($r('app.string.label_minutes'))
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
          Text('·')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
          Text(`${recipe.servings} `)
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
          Text($r('app.string.label_servings'))
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
  }
}
