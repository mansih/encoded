import React from 'react';
import PropTypes from 'prop-types';
import url from 'url';
import PubSub from 'pubsub-js';
import QueryString from '../libs/query_string';
import { Panel, PanelBody, TabPanel, TabPanelPane } from '../libs/ui/panel';
import { svgIcon } from '../libs/svg-icons';
import * as globals from './globals';
import { MatrixInternalTags } from './objectutils';
import { SearchControls } from './search';
import { SearchFilter } from './matrix';


/**
 * Maximum number of selected items that can be visualized.
 * @constant
 */
const VISUALIZE_LIMIT = 500;

const TARGET_MATRIX_UPDATED_CONTEXT_PUBSUB = 'target_matrix_updated_context_pubsub';
const TARGET_MATRIX_UPDATED_SPINNER_STATUS_PUBSUB = 'target_matrix_updated_spinner_status_pubsub';

const Spinner = ({ isSpinnerActive }) => (isSpinnerActive ?
        <div className="communicating">
            <div className="loading-spinner" />
        </div> :
        <div className="done">
            <span>&nbsp;</span>
        </div>);

Spinner.propTypes = {
    isSpinnerActive: PropTypes.bool,
};

Spinner.defaultProps = {
    isSpinnerActive: false,
};

class TargetTabPanel extends TabPanel {
    constructor(props) {
        super(props);

        this.clickUrl = this.clickUrl.bind(this);
        this.state.activeTabText = '';
    }

    clickUrl(e) {
        const updateTargetData = this.props.updateTargetData;
        const headerText = e.target.text;
        const assayTitle = e.target.dataset.assaytitle;
        const organismName = e.target.dataset.organismname;

        PubSub.publish(TARGET_MATRIX_UPDATED_SPINNER_STATUS_PUBSUB, true);

        this.context.fetch(e.target.href, {
            method: 'GET',
            headers: {
                Accept: 'application/json',
            },
        }).then((response) => {
            PubSub.publish(TARGET_MATRIX_UPDATED_SPINNER_STATUS_PUBSUB, false);

            if (response.ok) {
                return response.json();
            }
            return Promise.resolve(null);
        }).then((responseJson) => {
            this.setState({ activeTabText: headerText });
            if (!responseJson) {
                updateTargetData([]);
                return;
            }

            const x1 = responseJson.matrix.x.group_by[0];
            const x2 = responseJson.matrix.x.group_by[1];
            const xAxis = responseJson.matrix.x[x1].buckets.map(a => a[x2])
                .map(a => a.buckets)
                .reduce((a, b) => {
                    const m = a.concat(b);
                    return m;
                }, [])
                .map(x => x.key);
            const xAxisIndex = xAxis.reduce((x, y, z) => { x[y] = z; return x; }, []);
            const xAxisLength = xAxis.length;
            const y1 = responseJson.matrix.y.group_by[0];
            const y2 = responseJson.matrix.y.group_by[1];

            const yData = responseJson.matrix.y[y1].buckets
                .find(rBucket => rBucket.key === organismName)[y2].buckets
                .reduce((a, b) => {
                    const m = {};
                    m[b.key] = b[x1].buckets
                        .reduce((x, y) => {
                            x.push(y[x2].buckets
                                .reduce((i, j) => i.concat(j), []));
                            return x;
                        }, []);
                    a.push(m);
                    return a;
                }, []);

            const yAxisT = {};

            yData.forEach((y) => {
                const yKey = Object.keys(y)[0];
                // IE11 does not support .fill. So .map is used.
                yAxisT[yKey] = yAxisT[yKey] || [...Array(xAxisLength + 1)].map(x => 0);
                yAxisT[yKey][0] = yKey;

                const keyDocCountPair = y[yKey].reduce((a, b) => {
                    const m = a.concat(b);
                    return m;
                }, []);

                keyDocCountPair.forEach((kp) => {
                    const key = kp.key;
                    const docCount = kp.doc_count;
                    const index = xAxisIndex[key];
                    yAxisT[yKey][index + 1] = docCount;
                });
            });

            const yAxis = [];
            const keys = Object.keys(yAxisT);

            keys.forEach((key) => {
                yAxis.push(yAxisT[key]);
            });

            const targetData = { xAxis, yAxis, assayTitle, organismName };
            updateTargetData(targetData);
            PubSub.publish(TARGET_MATRIX_UPDATED_CONTEXT_PUBSUB, responseJson);
        });
    }

    render() {
        const { headers, navCss, moreComponents, moreComponentsClasses, tabFlange, decoration, decorationClasses } = this.props;
        let children = [];
        let firstPaneIndex = -1; // React.Children.map index of first <TabPanelPane> component

        // We expect to find <TabPanelPane> child elements inside <TabPanel>. For any we find, get
        // the React `key` value and copy it to an `id` value that we add to each child component.
        // That lets each child get an HTML ID matching `key` without having to pass both a key and
        // id with the same value. We also set the `active` property in the TabPanelPane component
        // here too so that each pane knows whether it's the active one or not. ### React14
        if (this.props.children) {
            children = React.Children.map(this.props.children, (child, i) => {
                if (child.type === TabPanelPane) {
                    firstPaneIndex = firstPaneIndex === -1 ? i : firstPaneIndex;

                    // Replace the existing child <TabPanelPane> component
                    const active = this.getCurrentTab() === child.key;
                    return React.cloneElement(child, { id: child.key, active });
                }
                return child;
            });
        }

        const baseUrl = this.context.location_href;

        return (
            <div className="target-matrix__data-wrapper">
                <div className="tab-nav">
                    <ul className={`nav-tabs${navCss ? ` ${navCss}` : ''}`} role="tablist">
                        {headers.map((header, i) => {
                            return (
                                <li key={i} role="presentation" aria-controls={header.title} className={this.state.activeTabText === header.title ? 'active' : ''}>
                                    <a href={`${baseUrl}&${header.url}&status=released`} ref={header.title} data-assaytitle={header.assayTitle} data-organismname={header.organismName} onClick={this.clickUrl} aria-controls={header.title} role="tab"  data-trigger="tab" role="tab" data-toggle="tab">
                                        {header.title}
                                    </a>
                                </li>
                            );
                        })}
                        {moreComponents ? <div className={moreComponentsClasses}>{moreComponents}</div> : null}
                    </ul>
                    {decoration ? <div className={decorationClasses}>{decoration}</div> : null}
                    {tabFlange ? <div className="tab-flange" /> : null}
                </div>
                <div className="tab-content">
                    {children}
                </div>
            </div>
        );
    }
}

TargetTabPanel.contextTypes = {
    location_href: PropTypes.string,
    navigate: PropTypes.func,
    fetch: PropTypes.func,
};

const TargetDataTable = ({ targetData }) => (
    targetData && targetData.length !== 0 ?
        <table className="matrix">
            <tbody>
                <tr className="matrix__col-category-header">
                    <td>&nbsp;</td>
                    {targetData.xAxis.map((termName, i) => {
                        return <th key={i} title={termName}>
                            <a href={`/search/?type=Experiment&status=released&replicates.library.biosample.donor.organism.scientific_name=${targetData.organismName}&biosample_ontology.term_name=${termName}&assay_title=${targetData.assayTitle}`}>
                                {termName}
                            </a>
                        </th>
                    }, { targetData })}
                </tr>
                {targetData.yAxis.map((tData, tIndex) => <tr className="target-matrix__row-data" key={tIndex}>
                    {tData.map((y, yIndex) => (yIndex === 0 ?
                            <th key={yIndex} title={y}>
                                <a href={`/search/?type=Experiment&status=released&target.label=${y}&assay_title=${targetData.assayTitle}&replicates.library.biosample.donor.organism.scientific_name=${targetData.organismName}`}>
                                    <span>{y}</span>
                                </a>
                            </th> :
                            <td key={yIndex} className={y !== 0 ? 'target-matrix__cell_has_content' : 'target-matrix__cell_no_has_content'} title={y}>
                                <a href={`/search/?type=Experiment&status=released&target.label=${tData[0]}&assay_title=${targetData.assayTitle}&biosample_ontology.term_name=${targetData.xAxis[yIndex - 1]}&replicates.library.biosample.donor.organism.scientific_name=${targetData.organismName}`}>
                                    <span>&nbsp;</span>
                                </a>
                            </td>), { targetData, tData })}
                    </tr>, { targetData })}
            </tbody>
        </table> :
        <div>No data <br /></div>
);

TargetDataTable.propTypes = {
    /** Whole table data */
    targetData: PropTypes.array,
};

TargetDataTable.defaultProps = {
    targetData: [],
};

class TargetMatrixPresentation extends React.Component {
    constructor(props) {
        super(props);

        // Determine whether a biosample classification has been specified in the query string, and
        // automatically expand the classification section if it has. Also cache the parsed URL and
        // analyzed query string as we need these later in the render.
        this.parsedUrl = url.parse(this.props.context['@id']);
        this.query = new QueryString(this.parsedUrl.query);
        this.handleTabClick = this.handleTabClick.bind(this);
        this.updateTargetData = this.updateTargetData.bind(this);

        this.state = {
            scrolledRight: false,
            targetData: null,
        };
    }

    // Handle a click on a tab.
    handleTabClick(tab) {
        const clickedOrganism = tab === 'All organisms' ? '' : tab;
        if (clickedOrganism) {
            this.query.replaceKeyValue('replicates.library.biosample.donor.organism.scientific_name', clickedOrganism);
        } else {
            this.query.deleteKeyValue('replicates.library.biosample.donor.organism.scientific_name');
        }
        this.parsedUrl.search = null;
        this.parsedUrl.query = null;
        const baseMatrixUrl = url.format(this.parsedUrl);
        this.context.navigate(decodeURIComponent(`${baseMatrixUrl}?${this.query.format()}`));
    }

    updateTargetData(targetData) {
        this.setState({
            targetData,
        });
    }

    render() {
        const { context } = this.props;
        const displayedContext = context;
        const { scrolledRight } = this.state;

        // Collect organisms for the tabs. `context` could change at any render, so we need to
        // calculate `organismTabs` every render. `context` does not change with the selected
        // organism tab.
        let availableOrganisms = [];
        const organismTabs = {};
        const headers = [];
        const organismFacet = context.facets.find(facet => facet.field === 'replicates.library.biosample.donor.organism.scientific_name');
        if (organismFacet) {
            availableOrganisms = organismFacet.terms.map(term => term.key);
            availableOrganisms.forEach((organismName) => {
                if ((context.matrix.viewableTabs || []).includes(organismName)) {
                    context.matrix.assay_titles.forEach((assayTitle) => {
                        const header = [organismName, ' | ', assayTitle].join('');
                        const key = `${organismName}&assay_title=${assayTitle}`;
                        organismTabs[key] = <i>{header}</i>;

                        headers.push({
                            organismName,
                            assayTitle,
                            title: header,
                            url: `replicates.library.biosample.donor.organism.scientific_name=${organismName}&assay_title=${assayTitle}`,
                        });
                    });
                }
            });
        }

        // Determine the currently selected tab from the query string.
        let selectedTab = null;
        const selectedOrganisms = this.query.getKeyValues('replicates.library.biosample.donor.organism.scientific_name');
        if (selectedOrganisms.length === 1) {
            // Query string specifies exactly one organism. Select the corresponding tab if it
            // exists, otherwise don't select a tab.
            selectedTab = availableOrganisms.includes(selectedOrganisms[0]) ? selectedOrganisms[0] : null;
        }

        return (
            <div className="matrix__presentation">
                <div className={`matrix__label matrix__label--horz${!scrolledRight ? ' horz-scroll' : ''}`}>
                    <span>{displayedContext.matrix.x.label}</span>
                    {svgIcon('largeArrow')}
                </div>
                <div className="matrix__presentation-content">
                    <div className="matrix__label matrix__label--vert"><div>{svgIcon('largeArrow')}{displayedContext.matrix.y.label}</div></div>
                    <TargetTabPanel headers={headers} tabs={organismTabs} selectedTab={selectedTab} updateTargetData={this.updateTargetData} handleTabClick={this.handleTabClick} tabPanelCss="matrix__data-wrapper">
                        {this.state.targetData ?
                              <div className="matrix__data" onScroll={this.handleOnScroll} ref={(element) => { this.scrollElement = element; }}>
                                  <TargetDataTable targetData={this.state.targetData} />
                              </div>
                          :
                              <div className="matrix__warning">
                                  Select an organism to view data.
                              </div>
                        }
                    </TargetTabPanel>
                </div>
            </div>);
    }
}

TargetMatrixPresentation.propTypes = {
    /** Matrix search result object */
    context: PropTypes.object.isRequired,
};

TargetMatrixPresentation.contextTypes = {
    navigate: PropTypes.func,
    location_href: PropTypes.string,
    session: PropTypes.object,
    session_properties: PropTypes.object,
};

const TargetMatrixContent = ({ context }) => (
    <div className="matrix__content matrix__content--reference-epigenome">
        <TargetMatrixPresentation context={context} />
    </div>
);

TargetMatrixContent.propTypes = {
    /** Matrix search result object */
    context: PropTypes.object.isRequired,
};

/**
 * Render the area above the matrix itself, including the page title.
 */
class TargetMatrixHeader extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            context: this.props.context,
            isSpinnerActive: false,
        };

        this.updateContext = this.updateContext.bind(this);
        this.updateDataLoadingStatus = this.updateDataLoadingStatus.bind(this);

        this.updateContextToken = PubSub.subscribe(TARGET_MATRIX_UPDATED_CONTEXT_PUBSUB, this.updateContext);
        this.updateDataLoadingStatusToken = PubSub.subscribe(TARGET_MATRIX_UPDATED_SPINNER_STATUS_PUBSUB, this.updateDataLoadingStatus);
    }

    updateContext(message, context) {
        this.setState({ context });
    }

    updateDataLoadingStatus(message, isSpinnerActive) {
        this.setState({ isSpinnerActive });
    }

    render() {
        const visualizeDisabledTitle = this.state.context.total > VISUALIZE_LIMIT ? `Filter to ${VISUALIZE_LIMIT} to visualize` : '';

        return (
            <div className="matrix-header">
                <Spinner isSpinnerActive={this.state.isSpinnerActive} />
                <div className="matrix-header__title">
                    <h1>{this.state.context.title}</h1>
                    <div className="matrix-tags">
                        <MatrixInternalTags context={this.state.context} />
                    </div>
                </div>
                <div className="matrix-header__controls">
                    <div className="matrix-header__filter-controls">
                        <SearchFilter context={this.state.context} />
                    </div>
                    <div className="matrix-header__search-controls">
                        <h4>Showing {this.state.context.total} results</h4>
                        <SearchControls context={this.state.context} visualizeDisabledTitle={visualizeDisabledTitle} hideBrowserSelector />
                    </div>
                </div>
            </div>
        );
    }
}


TargetMatrixHeader.propTypes = {
    /** Matrix search result object */
    context: PropTypes.object.isRequired,
};

const TargetMatrix = ({ context }) => {
    const itemClass = globals.itemClass(context, 'view-item');

    if (context.total > 0) {
        return (
            <Panel addClasses={itemClass}>
                <PanelBody>
                    <TargetMatrixHeader context={context} />
                    <TargetMatrixContent context={context} />
                </PanelBody>
            </Panel>
        );
    }
    return <h4>No results found</h4>;
};

TargetMatrix.propTypes = {
    context: PropTypes.object.isRequired,
};

TargetMatrix.contextTypes = {
    location_href: PropTypes.string,
    navigate: PropTypes.func,
    biosampleTypeColors: PropTypes.object, // DataColor instance for experiment project
};


globals.contentViews.register(TargetMatrix, 'TargetMatrix');
