import { combineReducers } from "redux";
import { StateType } from "typesafe-actions";

const rootReducer = combineReducers({});

export type RootState = StateType<typeof rootReducer>;

export default rootReducer;
