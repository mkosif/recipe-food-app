import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import CommonConstantsDb from '../constants/CommonConstantsDb';
import { RecipeSummary } from '../model/Recipe';
import Rdb from './Rdb';

export default class FavoriteTable {
  private table: Rdb;

  constructor(context: common.UIAbilityContext, callback: (err?: Error) => void = () => {}) {
    this.table = new Rdb(
      context,
      CommonConstantsDb.FAVORITE_TABLE.tableName,
      CommonConstantsDb.FAVORITE_TABLE.sqlCreate,
      CommonConstantsDb.FAVORITE_TABLE.columns
    );
    this.table.getRdbStore(callback);
  }

  clearAll(callback: (success: boolean) => void) {
    const predicates = new relationalStore.RdbPredicates(CommonConstantsDb.FAVORITE_TABLE.tableName);
    this.table.deleteData(predicates, callback);
  }

  dropTable(callback: (success: boolean) => void) {
    this.table.getRdbStore(() => {
      const sql = `DROP TABLE IF EXISTS ${CommonConstantsDb.FAVORITE_TABLE.tableName}`;
      this.table.executeSql(sql, (err?: Error) => callback(!err));
    });
  }

  getCount(callback: (count: number) => void) {
    this.table.getRdbStore(() => {
      const predicates = new relationalStore.RdbPredicates(CommonConstantsDb.FAVORITE_TABLE.tableName);
      this.table.query(predicates, (resultSet) => {
        callback(resultSet?.rowCount ?? 0);
      });
    });
  }

  isBookmarked(id: string, callback: (exists: boolean) => void) {
    this.table.getRdbStore(() => {
      const predicates = new relationalStore.RdbPredicates(CommonConstantsDb.FAVORITE_TABLE.tableName);
      predicates.equalTo('id', id);
      this.table.query(predicates, (resultSet) => {
        callback((resultSet?.rowCount ?? 0) > 0);
      });
    });
  }

  insertFavorite(recipe: RecipeSummary, callback: (success: boolean) => void) {
    const valueBucket: relationalStore.ValuesBucket = {
      id: recipe.id,
      name: recipe.name,
      imageSource: recipe.imageSource,
      description: recipe.description
    };

    this.table.getRdbStore(() => {
      this.table.insertData(valueBucket, callback, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE);
    });
  }

  deleteFavorite(id: string, callback: (success: boolean) => void) {
    const predicates = new relationalStore.RdbPredicates(CommonConstantsDb.FAVORITE_TABLE.tableName);
    predicates.equalTo('id', id);
    this.table.deleteData(predicates, callback);
  }

  getAll(callback: (recipes: RecipeSummary[]) => void) {
    this.table.getRdbStore(() => {
      const predicates = new relationalStore.RdbPredicates(CommonConstantsDb.FAVORITE_TABLE.tableName);
      this.table.query(predicates, (resultSet) => {
        if (!resultSet || resultSet.rowCount === 0) {
          callback([]);
          return;
        }

        const results: RecipeSummary[] = [];
        resultSet.goToFirstRow();
        for (let i = 0; i < resultSet.rowCount; i++) {
          const summary: RecipeSummary = {
            id: resultSet.getString(resultSet.getColumnIndex('id')),
            name: resultSet.getString(resultSet.getColumnIndex('name')),
            imageSource: resultSet.getString(resultSet.getColumnIndex('imageSource')),
            description: resultSet.getString(resultSet.getColumnIndex('description')),
            isFavorite: true
          };
          results.push(summary);
          resultSet.goToNextRow();
        }

        callback(results);
      });
    });
  }
}
