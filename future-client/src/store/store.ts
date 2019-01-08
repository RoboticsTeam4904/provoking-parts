import { applyMiddleware, compose, createStore } from "redux";
import { createEpicMiddleware } from "redux-observable";

import rootEpic from "./root-epic";
import rootReducer from "./root-reducer";

function configureStore(initialState?: {}) {
	const middlewares = [createEpicMiddleware(rootEpic)];
	const enhancer = compose(applyMiddleware(...middlewares));

	return createStore(rootReducer, initialState, enhancer);
}

const store = configureStore();

export default store;
