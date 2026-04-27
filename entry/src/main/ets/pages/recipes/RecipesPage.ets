import { common } from '@kit.AbilityKit';
import Recipe, { RecipeCategory } from '../../model/Recipe';
import RecipeRepository from '../../service/RecipeRepository';
import { categoryLabel, sortedCategories } from '../../util/CategoryUtil';
import { RecipeListRow } from '../../component/RecipeListRow';

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
            .fontSize(22)
            .fontColor($r('app.color.text_primary'))
            .onClick(() => this.navPathStack.pop())
            .width(28)
          Text($r('app.string.nav_recipes'))
            .fontSize(17)
            .fontWeight(900)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('⌕')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .padding(4)
            .width(28)
            .textAlign(TextAlign.Center)
            .onClick(() => this.navPathStack.pushPath({ name: 'SearchPage' }))
        }
        .width('92%')
        .padding({ top: 8, bottom: 4 })

        if (this.isLoading) {
          Text($r('app.string.msg_loading'))
            .fontColor($r('app.color.text_secondary'))
            .fontSize(12)
            .margin(16)
        } else {
          List({ space: 6 }) {
            ForEach(this.groups, (group: CategoryGroup) => {
              ListItemGroup({ header: this.buildHeader(group.category) }) {
                ForEach(group.recipes, (recipe: Recipe) => {
                  ListItem() {
                    RecipeListRow({ recipe: recipe });
                  }
                  .onClick(() => this.navPathStack.pushPathByName('DetailPage', recipe))
                }, (recipe: Recipe) => recipe.id)
              }
            }, (group: CategoryGroup) => group.category)
          }
          .sticky(StickyStyle.Header)
          .width('100%')
          .layoutWeight(1)
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
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
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.accent_primary'))
    }
    .width('70%')
    .padding({ left: 2, top: 8, bottom: 2 })
    .backgroundColor($r('app.color.background_primary'))
  }
}
