import { relationalStore } from '@kit.ArkData';
import CommonConstants from '../constants/CommonConstantsDb';
import Logger from '../util/Logger';
import { common } from '@kit.AbilityKit';

export default class Rdb {
  private rdbStore: relationalStore.RdbStore | null = null;
  private tableName: string;
  private sqlCreateTable: string;
  private columns: Array<string>;
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext, tableName: string, sqlCreateTable: string, columns: Array<string>) {
    this.context = context;
    this.tableName = tableName;
    this.sqlCreateTable = sqlCreateTable;
    this.columns = columns;
  }

  executeSql(sql: string, callback?: (err?: Error) => void): void {
    if (!this.rdbStore) {
      console.error('RDB store not initialized.');
      callback?.(new Error('RDB store is null'));
      return;
    }

    this.rdbStore.executeSql(sql, (err) => {
      if (err) {
        console.error('SQL execution failed:', err);
        callback?.(err);
      } else {
        console.info('SQL executed successfully');
        callback?.();
      }
    });
  }

  getRdbStore(callback: (err?: Error) => void = () => {}) {
    if (this.rdbStore !== null) {
      callback();
      return;
    }

    relationalStore.getRdbStore(this.context, CommonConstants.STORE_CONFIG, (err, rdb) => {
      if (err) {
        Logger.error(CommonConstants.RDB_TAG, `getRdbStore() failed, err: ${err.code}`);
        callback(err);
        return;
      }
      this.rdbStore = rdb;
      this.rdbStore.executeSql(this.sqlCreateTable);
      callback();
    });
  }

  insertData(
    data: relationalStore.ValuesBucket,
    callback: (success: boolean) => void = () => {},
    conflictResolution: relationalStore.ConflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_NONE
  ): void {
    if (!this.rdbStore) {
      callback(false);
      return;
    }
    this.rdbStore.insert(this.tableName, data, conflictResolution, (err, result) => {
      if (err) {
        Logger.error(CommonConstants.RDB_TAG, `insertData() failed, err: ${err}`);
        callback(false);
        return;
      }
      callback(result !== -1);
    });
  }

  deleteData(predicates: relationalStore.RdbPredicates, callback: (success: boolean) => void = () => {}) {
    if (!this.rdbStore) {
      callback(false);
      return;
    }
    this.rdbStore.delete(predicates, (err, ret) => {
      if (err) {
        Logger.error(CommonConstants.RDB_TAG, `deleteData() failed, err: ${err}`);
        callback(false);
        return;
      }
      callback(true);
    });
  }

  updateData(
    predicate: relationalStore.RdbPredicates,
    data: relationalStore.ValuesBucket,
    callback: (success: boolean) => void = () => {}
  ) {
    if (!this.rdbStore) {
      callback(false);
      return;
    }
    this.rdbStore.update(data, predicate, (err, ret) => {
      if (err) {
        Logger.error(CommonConstants.RDB_TAG, `updateData() failed, err: ${err}`);
        callback(false);
        return;
      }
      callback(true);
    });
  }

  query(
    predicates: relationalStore.RdbPredicates,
    callback: (resultSet: relationalStore.ResultSet | null) => void = () => {}
  ) {
    if (!this.rdbStore) {
      callback(null);
      return;
    }
    this.rdbStore.query(predicates, this.columns, (err, resultSet) => {
      if (err) {
        Logger.error(CommonConstants.RDB_TAG, `query() failed, err: ${err}`);
        callback(null);
        return;
      }
      callback(resultSet);
      resultSet.close();
    });
  }
}
