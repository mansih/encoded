import React from 'react';
import PropTypes from 'prop-types';
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

const getTargetData = (context, assayTitle, organismName) => {
    if (!context || !context.matrix || !context.matrix.x || !context.matrix.y || !assayTitle || !organismName || context.total === 0) {
        return null;
    }
    const x1 = context.matrix.x.group_by[0];
    const x2 = context.matrix.x.group_by[1];
    const xAxis = context.matrix.x[x1].buckets.map(a => a[x2])
        .map(a => a.buckets)
        .reduce((a, b) => {
            const m = a.concat(b);
            return m;
        }, [])
        .map(x => x.key);
    const xAxisIndex = xAxis.reduce((x, y, z) => { x[y] = z; return x; }, []);
    const xAxisLength = xAxis.length;
    const y1 = context.matrix.y.group_by[0];
    const y2 = context.matrix.y.group_by[1];

    const yData = context.matrix.y[y1].buckets
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
    return targetData;
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

        this.updateDataLoadingStatus = this.updateDataLoadingStatus.bind(this);
        this.updateDataLoadingStatusToken = PubSub.subscribe(TARGET_MATRIX_UPDATED_SPINNER_STATUS_PUBSUB, this.updateDataLoadingStatus);
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

const TargetMatrixContent = ({ context }) => (
    <div className="matrix__content matrix__content--reference-epigenome">
        <TargetMatrixPresentation context={context} />
    </div>
);

TargetMatrixContent.propTypes = {
    /** Matrix search result object */
    context: PropTypes.object.isRequired,
};


class TargetTabPanel extends TabPanel {
    render() {
        const { headers, context, navCss, moreComponents, moreComponentsClasses, tabFlange, decoration, decorationClasses, selectedTab } = this.props;
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

        // TODO: make this more automated
        const link = this.context.location_href;
        const query = new QueryString(link);
        const searchTerm = query.getKeyValues('searchTerm')[0];
        const searchText = searchTerm ? `&searchTerm=${searchTerm.trim()}` : '';
        const baseUrl = `/target-matrix/?type=Experiment${searchText}`; // this.context.location_href;

        return (
            <div className="target-matrix__data-wrapper">
                <div className="tab-nav">
                    <ul className={`nav-tabs${navCss ? ` ${navCss}` : ''}`} role="tablist">
                        {headers.map((header, i) => (
                            <li key={i} role="presentation" aria-controls={header.title} className={selectedTab === header.title ? 'active' : ''}>
                                <a href={`${baseUrl}&${header.url}&status=released`}>
                                    {header.title}
                                </a>
                            </li>
                        ))}
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
};

const TargetDataTable = ({ targetData }) => (
    targetData && targetData.length !== 0 ?
        <table className="matrix">
            <tbody>
                <tr className="matrix__col-category-header">
                    <td>&nbsp;</td>
                    {targetData.xAxis.map((termName, i) => <th key={i} title={termName}>
                        <a href={`/search/?type=Experiment&status=released&replicates.library.biosample.donor.organism.scientific_name=${targetData.organismName}&biosample_ontology.term_name=${termName}&assay_title=${targetData.assayTitle}`}>
                            {termName}
                        </a>
                    </th>, { targetData })}
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
    targetData: PropTypes.object,
};

TargetDataTable.defaultProps = {
    targetData: {},
};


class TargetMatrixPresentation extends React.Component {
    render() {
        const { context } = this.props;
        const headers = [
            {
                organismName: 'Homo sapiens',
                assayTitle: 'Histone ChIP-seq',
                title: 'Homo sapiens | Histone ChIP-seq',
                url: 'replicates.library.biosample.donor.organism.scientific_name=Homo sapiens&assay_title=Histone ChIP-seq',
            }, {
                organismName: 'Homo sapiens',
                assayTitle: 'TF ChIP-seq',
                title: 'Homo sapiens | TF ChIP-seq',
                url: 'replicates.library.biosample.donor.organism.scientific_name=Homo sapiens&assay_title=TF ChIP-seq',
            }, {
                organismName: 'Mus musculus',
                assayTitle: 'Histone ChIP-seq',
                title: 'Mus musculus | Histone ChIP-seq',
                url: 'replicates.library.biosample.donor.organism.scientific_name=Mus musculus&assay_title=Histone ChIP-seq',
            }, {
                organismName: 'Mus musculus',
                assayTitle: 'TF ChIP-seq',
                title: 'Mus musculus | TF ChIP-seq',
                url: 'replicates.library.biosample.donor.organism.scientific_name=Mus musculus&assay_title=TF ChIP-seq',
            },
        ];

        const link = context['@id'];
        const query = new QueryString(link);
        const scrolledRight = false;
        const assayTitle = query.getKeyValues('assay_title')[0];
        const organismName = query.getKeyValues('replicates.library.biosample.donor.organism.scientific_name')[0];
        const targetData = getTargetData(context, assayTitle, organismName);
        const selectedTab = `${organismName} | ${assayTitle}`;

        return (
            <div className="matrix__presentation">
                <div className={`matrix__label matrix__label--horz${!scrolledRight ? ' horz-scroll' : ''}`}>
                    <span>{context.matrix.x.label}</span>
                    {svgIcon('largeArrow')}
                </div>
                <div className="matrix__presentation-content">
                    <div className="matrix__label matrix__label--vert"><div>{svgIcon('largeArrow')}{context.matrix.y.label}</div></div>
                    <TargetTabPanel headers={headers} context={context} selectedTab={selectedTab} tabPanelCss="matrix__data-wrapper">
                        {targetData ?
                              <div className="matrix__data" onScroll={this.handleOnScroll} ref={(element) => { this.scrollElement = element; }}>
                                  <TargetDataTable targetData={targetData} />
                              </div>
                          :
                              <div className="matrix__warning">
                                  { context.total === 0 ? 'No data to display' : 'Select an organism to view data.' }
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

const TargetMatrix = ({ context }) => {
    const itemClass = globals.itemClass(context, 'view-item');

    return (
        <Panel addClasses={itemClass}>
            <PanelBody>
                <TargetMatrixHeader context={context} />
                <TargetMatrixContent context={context} />
            </PanelBody>
        </Panel>
    );
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
